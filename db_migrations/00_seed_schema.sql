CREATE TABLE IF NOT EXISTS predict_passes(
    sat_name text not null,
    pass_start timestamp primary key default (strftime('%s', 'now')) not null,
    pass_end timestamp default (strftime('%s', 'now')) not null,
    max_elev int not null,
    is_active boolean);

CREATE TABLE IF NOT EXISTS decoded_passes(
    id integer primary key autoincrement,
    pass_start integer,
    file_path text not null,
    daylight_pass boolean, is_noaa boolean, sat_type integer, img_count integer,
    foreign key(pass_start) references passes(pass_start));
