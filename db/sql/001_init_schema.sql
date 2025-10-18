-- Create the database (run this part separately if needed)
-- CREATE DATABASE neuro_assets_db;

-- 0. Enable UUID generator (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE public."asset_type_enum" AS ENUM (
	'img',
	'video',
	'audio');

CREATE TYPE public."generation_status_enum" AS ENUM (
	'pending',
	'in_progress',
	'completed',
	'failed');

-- 2. Partner Store (root entity - UUID instead of BIGSERIAL)
CREATE TABLE partner_store (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('shopify', 'woocommerce')),
    store_identifier VARCHAR(255) NOT NULL UNIQUE,   -- shop.myshopify.com OR WooCommerce store ID
    api_key VARCHAR(255),
    store_contact_email VARCHAR(100) NOT NULL,
    store_contact_name VARCHAR(100) NOT NULL,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Asset
CREATE TABLE asset (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES partner_store(id) ON DELETE CASCADE,
    asset_type asset_type_enum NOT NULL,
    prompt TEXT NOT NULL,
    negative_prompt TEXT,
    seed INT,
    steps INT,
    sampler VARCHAR(50),
    guidance_scale DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

 -- 4. Image Asset
-- Option A: If multiple images per asset
CREATE TABLE image_asset (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id uuid NOT NULL,
    resolution varchar(20) NULL,
	format varchar(10) NULL,
	meta_data jsonb NULL,
	input_url text NULL
);

-- 5. Video Asset
-- Option A: If multiple images per asset
CREATE TABLE video_asset (
    id BIGSERIAL PRIMARY KEY,                         -- internal unique ID
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,  -- links to parent asset
    resolution VARCHAR(20),                           -- e.g., "1920x1080", "1280x720"
    format VARCHAR(10),                               -- e.g., "mp4", "mov", "webm"
    duration_sec INT,                                 -- video length in seconds
    frame_rate DECIMAL(5,2),                          -- frames per second
    meta_data JSONB                                    -- additional info (AI params, tags, storage URLs, etc.)
    input_url text NULL,
);

-- 6. Audio Asset  
CREATE TABLE audio_asset (
    id BIGSERIAL PRIMARY KEY,
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,
    format VARCHAR(10),             -- "mp3", "wav", "aac"
    duration_sec INT,               -- audio length in seconds
    bitrate_kbps INT,               -- audio bitrate
    sample_rate INT,                -- in Hz, e.g., 44100
    channels INT,                   -- 1=mono, 2=stereo
    meta_data JSONB                  -- AI params, tags, storage info, transcription, etc.
    input_url text NULL;
);

-- 7. 
CREATE TABLE asset_generation (
    id BIGSERIAL PRIMARY KEY,                      -- internal sequential ID
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,  -- matches asset UUID
    request_id UUID DEFAULT gen_random_uuid(),     -- unique request identifier
    model_name VARCHAR(100) NOT NULL,             -- e.g., "stable-diffusion-1.5", "sdxl"
    status generation_status_enum NOT NULL DEFAULT 'pending',

    -- Core AI generation parameters
    prompt TEXT NOT NULL,
    negative_prompt TEXT,
    seed INT,
    steps INT,
    sampler VARCHAR(50),
    guidance_scale DECIMAL(5,2),

    -- Output info
    output_url TEXT,               -- link to generated asset
    output_meta_data JSONB,         -- e.g., inference time, device info, size

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE style_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- NULL = global template, otherwise belongs to a specific store
    store_id UUID NULL,

    name VARCHAR(100) NOT NULL,
    description TEXT,
    prompt TEXT NOT NULL,
    negative_prompt TEXT,
    seed INT,
    steps INT,
    sampler VARCHAR(50),
    guidance_scale DECIMAL(5,2),

    meta_data JSONB,

    created_by VARCHAR(100) NOT NULL DEFAULT 'system',  -- default is 'system'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Foreign Key
    CONSTRAINT fk_style_store FOREIGN KEY (store_id) REFERENCES partner_store(id) ON DELETE CASCADE
);

-- DROP TABLE public.batch_job;

CREATE TABLE public.batch_job (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	store_id uuid NOT NULL,
	job_type varchar(50) NOT NULL,
	template_id uuid NULL,
	parameters jsonb NULL,
	status varchar(20) DEFAULT 'pending'::character varying NOT NULL,
	created_by varchar(100) DEFAULT 'system'::character varying NOT NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	CONSTRAINT batch_job_pkey PRIMARY KEY (id)
);

-- public.batch_job foreign keys

ALTER TABLE public.batch_job ADD CONSTRAINT batch_job_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.partner_store(id) ON DELETE CASCADE;
ALTER TABLE public.batch_job ADD CONSTRAINT batch_job_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.style_template(id) ON DELETE SET NULL;

-------- Table for batch jobs --------

CREATE TABLE batch_job_asset (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_job_id UUID NOT NULL REFERENCES batch_job(id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, processing, done, failed

    -- Nullable, because it will be filled only after generation is done
    result_asset_generation_id BIGSERIAL,
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(batch_job_id, asset_id),

    CONSTRAINT fk_batch_job FOREIGN KEY (batch_job_id) REFERENCES batch_job(id) ON DELETE CASCADE,
    CONSTRAINT fk_batch_asset FOREIGN KEY (asset_id) REFERENCES asset(id) ON DELETE CASCADE,
    CONSTRAINT fk_batch_result FOREIGN KEY (result_asset_generation_id) REFERENCES asset_generation(id) ON DELETE SET NULL
);


-- DB for job processing --

ALTER TABLE asset_generation
ADD COLUMN retry_count INT DEFAULT 0,
ADD COLUMN last_error TEXT;  -- quick access to the most recent error

CREATE TABLE asset_generation_attempts (
    id BIGSERIAL PRIMARY KEY,
    generation_id BIGINT NOT NULL REFERENCES asset_generation(id) ON DELETE CASCADE,
    attempt_number INT NOT NULL,               -- 1, 2, 3...
    status generation_status_enum NOT NULL,    -- 'in_progress', 'failed', 'completed'
    error_message TEXT,                        -- if failed
    worker_name VARCHAR(100),                  -- which worker handled it
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP
);


CREATE TABLE dead_letter_log (
    id BIGSERIAL PRIMARY KEY,
    generation_id BIGINT NOT NULL REFERENCES asset_generation(id) ON DELETE CASCADE,
    final_error TEXT NOT NULL,
    failed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    worker_name VARCHAR(100),
    retried BOOLEAN DEFAULT FALSE             -- if manually retried later
);

-- =========================================================
-- 1️⃣  SUBSCRIPTION PLAN MASTER
-- =========================================================
CREATE TABLE subscription_plan (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,            -- Starter, Growth, Pro
    price DECIMAL(10,2) NOT NULL,                -- Shopify charge in USD
    credits INT NOT NULL,                        -- number of images included
    description TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);


-- =========================================================
-- 2️⃣  STORE SUBSCRIPTION (Shopify-managed)
-- =========================================================
CREATE TABLE store_subscription (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES partner_store(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plan(id) ON DELETE RESTRICT,
    shopify_subscription_id VARCHAR(100) UNIQUE,  -- from Shopify Billing API
    start_date TIMESTAMP DEFAULT now(),
    end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (store_id, plan_id, is_active)
);

-- =========================================================
-- 3️⃣  USAGE CREDIT TRACKER
-- =========================================================
CREATE TABLE usage_credit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES partner_store(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES store_subscription(id) ON DELETE SET NULL,
    total_credits INT NOT NULL DEFAULT 5,        -- 5 default images on install
    used_credits INT NOT NULL DEFAULT 0,
    reset_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CHECK (used_credits <= total_credits)
);


-- =========================================================
-- 4️⃣  USAGE AUDIT LOG
-- =========================================================
CREATE TABLE usage_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES partner_store(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES store_subscription(id) ON DELETE SET NULL,
    asset_generation_id BIGSERIAL REFERENCES asset_generation(id) ON DELETE SET NULL,
    change INT NOT NULL,                         -- + or - credits
    reason VARCHAR(100),                         -- e.g. 'image_generated', 'bonus_credits'
    created_at TIMESTAMP DEFAULT now()
);
