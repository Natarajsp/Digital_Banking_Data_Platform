"""
Digital Banking Data Platform - Kafka Transaction Producer
------------------------------------------------------------
Streams synthetic banking transaction events to a Kafka topic in real time,
following the schema agreed in the Source Architecture doc:

    transaction_id, customer_id, account_id, branch_id, transaction_type,
    channel, amount, currency, status, transaction_timestamp

Every event references a real customer_id/account_id/branch_id combination
pulled from sqlserver/accounts.csv, so downstream Bronze ingestion has no
orphan records - consistent with the static kafka/transactions.json sample.

Usage:
    pip install kafka-python
    python transaction_producer.py --bootstrap-servers localhost:9092 --topic bank.transactions
    python transaction_producer.py --dry-run --rate 5 --count 50   # no broker needed, prints to stdout

Env vars (used if the matching flag isn't passed):
    KAFKA_BOOTSTRAP_SERVERS, KAFKA_TOPIC
"""
import argparse
import csv
import json
import os
import random
import time
import uuid
from datetime import datetime, timezone

CHANNELS = ["ATM", "Mobile Banking", "Internet Banking", "Branch", "POS"]
CHANNEL_WEIGHTS = [0.18, 0.34, 0.22, 0.10, 0.16]
TXN_TYPES = ["Deposit", "Withdrawal", "Transfer", "Bill Payment", "Card Payment"]
TXN_TYPE_WEIGHTS = [0.20, 0.22, 0.25, 0.16, 0.17]
STATUSES = ["Success", "Failed", "Pending"]
STATUS_WEIGHTS = [0.955, 0.03, 0.015]


def load_accounts(path):
    """Read sqlserver/accounts.csv so every produced event maps to a real account."""
    accounts = []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            accounts.append((row["account_id"], row["customer_id"], row["branch_id"]))
    if not accounts:
        raise RuntimeError(f"No accounts found in {path}")
    return accounts


def make_event(accounts, seq):
    account_id, customer_id, branch_id = random.choice(accounts)
    txn_type = random.choices(TXN_TYPES, weights=TXN_TYPE_WEIGHTS)[0]
    amount = round(random.lognormvariate(8.2, 1.1), 2)
    if txn_type in ("Bill Payment", "Card Payment"):
        amount = round(amount * 0.25, 2)
    amount = max(50.0, min(amount, 800_000.0))
    return {
        "transaction_id": f"TXN{uuid.uuid4().hex[:10].upper()}",
        "customer_id": customer_id,
        "account_id": account_id,
        "branch_id": branch_id,
        "transaction_type": txn_type,
        "channel": random.choices(CHANNELS, weights=CHANNEL_WEIGHTS)[0],
        "amount": amount,
        "currency": "INR",
        "status": random.choices(STATUSES, weights=STATUS_WEIGHTS)[0],
        "transaction_timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


def run(args):
    accounts = load_accounts(args.accounts_csv)
    print(f"Loaded {len(accounts)} accounts from {args.accounts_csv}")

    producer = None
    if not args.dry_run:
        from kafka import KafkaProducer  # pip install kafka-python

        producer = KafkaProducer(
            bootstrap_servers=args.bootstrap_servers.split(","),
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
            key_serializer=lambda k: k.encode("utf-8"),
            acks="all",
            linger_ms=50,
        )
        print(f"Connected to Kafka at {args.bootstrap_servers}, publishing to topic '{args.topic}'")
    else:
        print("--dry-run: printing events to stdout instead of publishing to Kafka")

    sent = 0
    try:
        while args.count == 0 or sent < args.count:
            event = make_event(accounts, sent)
            if producer:
                producer.send(args.topic, key=event["account_id"], value=event)
            else:
                print(json.dumps(event))
            sent += 1
            if args.rate > 0:
                time.sleep(1.0 / args.rate)
    except KeyboardInterrupt:
        print("\nStopped by user.")
    finally:
        if producer:
            producer.flush()
            producer.close()
        print(f"Produced {sent} transaction events.")


def parse_args():
    p = argparse.ArgumentParser(description="Simulate a Kafka producer for banking transactions")
    p.add_argument("--bootstrap-servers", default=os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"))
    p.add_argument("--topic", default=os.environ.get("KAFKA_TOPIC", "bank.transactions"))
    p.add_argument("--accounts-csv", default=os.path.join(os.path.dirname(__file__), "..", "sqlserver", "accounts.csv"))
    p.add_argument("--rate", type=float, default=10, help="events per second (0 = as fast as possible)")
    p.add_argument("--count", type=int, default=0, help="number of events to send (0 = run forever)")
    p.add_argument("--dry-run", action="store_true", help="print events instead of requiring a real Kafka broker")
    return p.parse_args()


if __name__ == "__main__":
    run(parse_args())
