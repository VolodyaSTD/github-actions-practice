import os

import psycopg2
from flask import Flask, jsonify, render_template

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("APP_SECRET", "dev")


def get_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
    )


def fetch_items():
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, name, price FROM items ORDER BY id")
        return [{"id": r[0], "name": r[1], "price": float(r[2])} for r in cur.fetchall()]


@app.route("/")
def index():
    return render_template("index.html", items=fetch_items())


@app.route("/health")
def health():
    try:
        with get_connection() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")
        return jsonify(status="ok", database="connected")
    except Exception as exc:
        return jsonify(status="error", database="disconnected", error=str(exc)), 503


@app.route("/api/items")
def api_items():
    return jsonify(fetch_items())


@app.route("/api/items/count")
def api_items_count():
    return str(len(fetch_items()))
