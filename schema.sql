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