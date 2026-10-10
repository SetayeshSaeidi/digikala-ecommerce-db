CREATE TYPE "order_status" AS ENUM (
  'Pending',
  'Shipped',
  'Delivered',
  'Cancelled'
);

CREATE TYPE "payment_status" AS ENUM (
  'Pending',
  'Successful',
  'Failed',
  'Refunded'
);

CREATE TYPE "payment_method" AS ENUM (
  'CreditCard',
  'OnlineBanking',
  'Wallet'
);

CREATE TABLE "users" (
  "id" bigserial PRIMARY KEY,
  "email" varchar(255) UNIQUE NOT NULL,
  "password_hash" varchar(255) NOT NULL,
  "first_name" varchar(100),
  "last_name" varchar(100),
  "phone" varchar(20),
  "is_premium" boolean NOT NULL DEFAULT false,
  "premium_started_at" timestamp,
  "premium_expires_at" timestamp,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "addresses" (
  "id" bigserial PRIMARY KEY,
  "user_id" bigint NOT NULL,
  "recipient" varchar(100),
  "street" varchar(255),
  "city" varchar(100),
  "state" varchar(100),
  "postal_code" varchar(20),
  "country" varchar(100),
  "phone" varchar(20),
  "is_default" boolean NOT NULL DEFAULT false,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "categories" (
  "id" bigserial PRIMARY KEY,
  "name" varchar(100) UNIQUE NOT NULL,
  "parent_id" bigint
);

CREATE TABLE "products" (
  "id" bigserial PRIMARY KEY,
  "title" varchar(255) NOT NULL,
  "description" text,
  "price" numeric(12,2) NOT NULL,
  "upload_date" date NOT NULL DEFAULT CURRENT_DATE,
  "rating_avg" numeric(3,2),
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "product_categories" (
  "product_id" bigint,
  "category_id" bigint,
  PRIMARY KEY ("product_id", "category_id")
);

CREATE TABLE "product_attributes" (
  "id" bigserial PRIMARY KEY,
  "name" varchar(100) UNIQUE NOT NULL,
  "data_type" varchar(20) NOT NULL,
  "unit" varchar(50)
);

CREATE TABLE "product_attribute_values" (
  "product_id" bigint,
  "attribute_id" bigint,
  "value_text" text NOT NULL,
  PRIMARY KEY ("product_id", "attribute_id")
);

CREATE TABLE "inventory" (
  "product_id" bigint PRIMARY KEY,
  "quantity" int NOT NULL,
  "last_updated" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "carts" (
  "id" bigserial PRIMARY KEY,
  "user_id" bigint UNIQUE NOT NULL,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "cart_items" (
  "cart_id" bigint,
  "product_id" bigint,
  "quantity" int NOT NULL DEFAULT 1,
  PRIMARY KEY ("cart_id", "product_id")
);

CREATE TABLE "discounts" (
  "id" bigserial PRIMARY KEY,
  "code" varchar(50) UNIQUE NOT NULL,
  "percent" numeric(5,2) NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "max_usage" int,
  "usage_count" int NOT NULL DEFAULT 0,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "orders" (
  "id" bigserial PRIMARY KEY,
  "user_id" bigint NOT NULL,
  "shipping_address_id" bigint NOT NULL,
  "discount_id" bigint,
  "total_amount" numeric(12,2) NOT NULL,
  "status" order_status NOT NULL DEFAULT 'Pending',
  "placed_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "shipped_at" timestamp,
  "delivered_at" timestamp,
  "cancelled_at" timestamp
);

CREATE TABLE "order_items" (
  "order_id" bigint,
  "product_id" bigint,
  "quantity" int NOT NULL,
  "price_each" numeric(12,2) NOT NULL,
  PRIMARY KEY ("order_id", "product_id")
);

CREATE TABLE "payments" (
  "order_id" bigint PRIMARY KEY,
  "amount" numeric(12,2) NOT NULL,
  "payment_date" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "status" payment_status NOT NULL DEFAULT 'Pending',
  "method" payment_method NOT NULL,
  "transaction_ref" varchar(255)
);

CREATE TABLE "reviews" (
  "id" bigserial PRIMARY KEY,
  "user_id" bigint,
  "product_id" bigint,
  "rating" smallint NOT NULL,
  "comment" text,
  "created_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX ON "reviews" ("user_id", "product_id");

ALTER TABLE "addresses" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "categories" ADD FOREIGN KEY ("parent_id") REFERENCES "categories" ("id");

ALTER TABLE "product_categories" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "product_categories" ADD FOREIGN KEY ("category_id") REFERENCES "categories" ("id");

ALTER TABLE "product_attribute_values" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "product_attribute_values" ADD FOREIGN KEY ("attribute_id") REFERENCES "product_attributes" ("id");

ALTER TABLE "inventory" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "carts" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "cart_items" ADD FOREIGN KEY ("cart_id") REFERENCES "carts" ("id");

ALTER TABLE "cart_items" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "orders" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "orders" ADD FOREIGN KEY ("shipping_address_id") REFERENCES "addresses" ("id");

ALTER TABLE "orders" ADD FOREIGN KEY ("discount_id") REFERENCES "discounts" ("id");

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id");

ALTER TABLE "order_items" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");

ALTER TABLE "payments" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id");

ALTER TABLE "reviews" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");

ALTER TABLE "reviews" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id");
