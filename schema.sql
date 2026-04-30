drop schema if exists delivery cascade;
create schema delivery;
set search_path = delivery;

create table counterparties (
    id bigint generated always as identity primary key,
    counterparty_type text not null,
    name text not null,
    phone text,
    email text,
    inn text,
    created_at timestamptz not null default now(),

    constraint counterparties_type_check check (counterparty_type in ('person', 'company')),
    constraint counterparties_name_check check (length(trim(name)) > 0),
    constraint counterparties_email_unique unique (email),
    constraint counterparties_inn_unique unique (inn)
);

create table offices (
    id bigint generated always as identity primary key,
    code text not null,
    name text not null,
    city text not null,
    address text not null,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),

    constraint offices_code_unique unique (code),
    constraint offices_code_check check (length(trim(code)) > 0),
    constraint offices_name_check check (length(trim(name)) > 0),
    constraint offices_city_check check (length(trim(city)) > 0),
    constraint offices_address_check check (length(trim(address)) > 0)
);

create table parcel_statuses (
    id smallint generated always as identity primary key,
    code text not null,
    name text not null,
    sort_order integer not null,
    is_final boolean not null default false,
    created_at timestamptz not null default now(),

    constraint parcel_statuses_code_unique unique (code),
    constraint parcel_statuses_sort_order_unique unique (sort_order),
    constraint parcel_statuses_code_check check (length(trim(code)) > 0),
    constraint parcel_statuses_name_check check (length(trim(name)) > 0),
    constraint parcel_statuses_sort_order_check check (sort_order > 0)
);

create table tariffs (
    id bigint generated always as identity primary key,
    code text not null,
    name text not null,
    description text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),

    constraint tariffs_code_unique unique (code),
    constraint tariffs_code_check check (length(trim(code)) > 0),
    constraint tariffs_name_check check (length(trim(code)) > 0)
);

create table tariff_versions (
    if bigint generated always as identity primary key,
    tariff_id bigint not null,
    version_number integer not null,
    valid_from timestamptz not null,
    valid_to timestamptz,
    min_weight_kg numeric(10, 3) not null default 0,
    max_weight_kg numeric(10, 3) not null,
    max_length_cm numeric(10, 2) not null,
    max_width_cm numeric(10, 2) not null,
    max_height_cm numeric(10, 2) not null,
    delivery_days_min integer not null,
    delivery_days_max integer not null,
    base_price numeric(12, 2) not null,
    price_per_kg numeric(12, 2) not null default 0,
    created_at timestamptz not null default now(),

    constraint tariff_versions_tariff_id_fk foreign key (tariff_id) references tariffs(id),
    constraint tariff_versions_tariff_version_unique unique (tariff_id, version_number),
    constraint tariff_versions_period_check check (valid_to is null or valid_to > valid_from),
    constraint tariff_versions_weight_check check (min_weight_kg >= 0 and max_weight_kg > min_weight_kg),
    constraint tariff_versions_size_check check (max_length_cm > 0 and max_width_cm > 0 and max_height_cm > 0),
    constraint tariff_versions_days_check check (delivery_days_min > 0 and delivery_days_max >= delivery_days_min),
    constraint tariff_versions_price_check check (base_price >= 0 and price_per_kg >= 0)
);