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
    constraint tariffs_name_check check (length(trim(name)) > 0)
);

create table tariff_versions (
    id bigint generated always as identity primary key,
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

create table parcels (
    id bigint generated always as identity primary key,
    tracking_number text not null,
    sender_id bigint not null,
    recipient_id bigint not null,
    payer_id bigint not null,
    origin_office_id bigint not null,
    destination_office_id bigint not null,
    current_office_id bigint not null,
    current_status_id smallint not null,
    tariff_version_id bigint not null,
    weight_kg numeric(10, 3) not null,
    length_cm numeric(10, 2) not null,
    width_cm numeric(10, 2) not null,
    height_cm numeric(10, 2) not null,
    declared_value numeric(12, 2) not null default 0,
    delivery_price numeric(12, 2) not null,
    created_at timestamptz not null default now(),
    sent_at timestamptz,
    delivered_at timestamptz,

    constraint parcels_tracking_number_unique unique (tracking_number),
    constraint parcels_sender_id_fk foreign key (sender_id) references counterparties(id),
    constraint parcels_recipient_id_fk foreign key (recipient_id) references counterparties(id),
    constraint parcels_payer_id_fk foreign key (payer_id) references counterparties(id),
    constraint parcels_origin_office_id_fk foreign key (origin_office_id) references offices(id),
    constraint parcels_destination_office_id_fk foreign key (destination_office_id) references offices(id),
    constraint parcels_current_office_id_fk foreign key (current_office_id) references offices(id),
    constraint parcels_current_status_id_fk foreign key (current_status_id) references parcel_statuses(id),
    constraint parcels_tariff_version_id_fk foreign key (tariff_version_id) references tariff_versions(id),
    constraint parcels_tracking_number_check check (length(trim(tracking_number)) > 0),
    constraint parcels_weight_check check (weight_kg > 0),
    constraint parcels_size_check check (length_cm > 0 and width_cm > 0 and height_cm > 0),
    constraint parcels_price_check check (declared_value >= 0 and delivery_price >= 0),
    constraint parcels_sent_at_check check (sent_at is null or sent_at >= created_at),
    constraint parcels_delivered_at_check check (delivered_at is null or (sent_at is not null and delivered_at >= sent_at))
);

create table parcel_status_history (
    id bigint generated always as identity primary key,
    parcel_id bigint not null,
    status_id smallint not null,
    office_id bigint,
    changed_at timestamptz not null default now(),
    comment text,

    constraint parcel_status_history_parcel_id_fk foreign key (parcel_id) references parcels(id),
    constraint parcel_status_history_status_id_fk foreign key (status_id) references parcel_statuses(id),
    constraint parcel_status_history_office_id_fk foreign key (office_id) references offices(id)
);

create table parcel_movements (
    id bigint generated always as identity primary key,
    parcel_id bigint not null,
    from_office_id bigint not null,
    to_office_id bigint not null,
    departed_at timestamptz not null,
    arrived_at timestamptz,
    created_at timestamptz not null default now(),

    constraint parcel_movements_parcel_id_fk foreign key (parcel_id) references parcels(id),
    constraint parcel_movements_from_office_id_fk foreign key (from_office_id) references offices(id),
    constraint parcel_movements_to_office_id_fk foreign key (to_office_id) references offices(id),
    constraint parcel_movements_offices_check check (from_office_id <> to_office_id),
    constraint parcel_movements_arrived_at_check check (arrived_at is null or arrived_at >= departed_at)
);

create index parcels_current_status_id_idx on parcels (current_status_id);
create index parcels_current_office_id_idx on parcels (current_office_id);
create index parcels_sender_id_idx on parcels (sender_id);
create index parcels_recipient_id_idx on parcels (recipient_id);
create index parcels_tariff_version_id_idx on parcels (tariff_version_id);

create index parcel_status_history_parcel_id_changed_at_idx
on parcel_status_history (parcel_id, changed_at desc);

create index parcel_movements_parcel_id_departed_at_idx
on parcel_movements (parcel_id, departed_at desc);

create index tariff_versions_tariff_id_valid_from_idx
on tariff_versions (tariff_id, valid_from desc);

-- комментарии

comment on table counterparties is 'контрагенты: физические лица и компании, которые участвуют в доставке';
comment on column counterparties.counterparty_type is 'тип контрагента: физическое лицо или компания';

comment on table offices is 'офисы, где принимают, хранят, сортируют или выдают посылки';
comment on column offices.is_active is 'если false, офис не используют для новых посылок';

comment on table parcel_statuses is 'справочник возможных статусов посылки';
comment on column parcel_statuses.is_final is 'признак статуса, после которого доставка завершена или отменена';

comment on table tariffs is 'справочник услуг доставки';
comment on column tariffs.is_active is 'если false, тариф не выбирают для новых посылок';

comment on table tariff_versions is 'условия тарифа, которые действуют в заданный период';
comment on column tariff_versions.tariff_id is 'услуга доставки, к которой относится эта версия условий';
comment on column tariff_versions.valid_from is 'дата и время начала действия версии тарифа';
comment on column tariff_versions.valid_to is 'дата и время конца действия версии тарифа';
comment on column tariff_versions.min_weight_kg is 'минимальный вес посылки для этой версии тарифа';
comment on column tariff_versions.max_weight_kg is 'максимальный вес посылки для этой версии тарифа';
comment on column tariff_versions.base_price is 'базовая цена по этой версии тарифа';
comment on column tariff_versions.price_per_kg is 'доплата за каждый килограмм по этой версии тарифа';

comment on table parcels is 'посылки с текущим статусом, текущим офисом и выбранной версией тарифа';
comment on column parcels.tracking_number is 'уникальный номер посылки для поиска';
comment on column parcels.sender_id is 'контрагент, который отправляет посылку';
comment on column parcels.recipient_id is 'контрагент, который получает посылку';
comment on column parcels.payer_id is 'контрагент, который оплачивает доставку';
comment on column parcels.current_office_id is 'офис, где посылка находится сейчас';
comment on column parcels.current_status_id is 'текущий статус посылки';
comment on column parcels.tariff_version_id is 'версия тарифа, зафиксированная при оформлении посылки';
comment on column parcels.delivery_price is 'итоговая цена доставки для этой посылки';

comment on table parcel_status_history is 'история смены статусов посылки';
comment on column parcel_status_history.office_id is 'офис, где посылка получила этот статус';
comment on column parcel_status_history.changed_at is 'дата и время смены статуса';

comment on table parcel_movements is 'история движения посылки между офисами';
comment on column parcel_movements.from_office_id is 'офис, из которого отправили посылку';
comment on column parcel_movements.to_office_id is 'офис, куда отправили посылку';
comment on column parcel_movements.departed_at is 'дата и время выхода из офиса';
comment on column parcel_movements.arrived_at is 'дата и время прибытия в офис';
