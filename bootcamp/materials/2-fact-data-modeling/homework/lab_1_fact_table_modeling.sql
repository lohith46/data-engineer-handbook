-- with deduped as (
--     select
--         g.game_date_est,
--         gd.*,
--         row_number() over (partition by gd.game_id, team_id, player_id order by g.game_date_est) as row_num
--     from game_details gd JOIN games g on gd.game_id = g.game_id
-- )
-- select *
-- from deduped
-- where row_num = 1

-- Columns to care about

CREATE table fct_game_details(
                                 dim_game_date DATE,
                                 dim_season integer,
                                 dim_team_id integer,
                                 dim_player_id integer,
                                 dim_player_name TEXT,
                                 dim_start_position TEXT,
                                 dim_did_not_play boolean,
                                 dim_did_not_dress boolean,
                                 dim_not_with_team boolean,
                                 dim_is_playing_at_home boolean,
                                 m_minutes REAL,
                                 m_gfm integer,
                                 m_gfa integer,
                                 m_fg3m integer,
                                 m_fg3a integer,
                                 m_fta integer,
                                 m_oreb integer,
                                 m_dreb integer,
                                 m_reb integer,
                                 m_ast integer,
                                 m_stl integer,
                                 m_blk integer,
                                 m_turnovers integer,
                                 m_pf integer,
                                 m_pts integer,
                                 m_plus_minus integer,
                                 PRIMARY KEY (dim_game_date, dim_team_id, dim_player_id)
);

INSERT into fct_game_details
with deduped as (
    select
        g.game_date_est,
        g.season,
        g.home_team_id,
        gd.*,
        row_number() over (partition by gd.game_id, team_id, player_id order by g.game_date_est) as row_num
    from game_details gd JOIN games g on gd.game_id = g.game_id
)
select game_date_est as dim_game_date,
       season as dim_season,
       team_id as dim_team_id,
       player_id as dim_player_id,
       player_name as dim_player_name,
       start_position as dim_start_position,
       COALESCE(POSITION ('DNP' in comment), 0) > 0 as dim_did_not_play,
       COALESCE(POSITION ('DND' in comment), 0) > 0 as dim_did_not_dress,
       COALESCE(POSITION ('NWT' in comment), 0) > 0 as dim_not_with_team,
       team_id = home_team_id as dim_is_playing_at_home,
       CAST(split_part(min, ':', 1) as REAL) +
       CAST(split_part(min, ':', 2) as REAL)/60 as m_minutes,
       fgm as m_gfm,
       fga as m_fga,
       fg3m as m_fg3m,
       fg3a as m_fg3a,
       fta as m_fta,
       oreb as m_oreb,
       dreb as m_dreb,
       reb as m_reb,
       ast as m_ast,
       stl as m_stl,
       blk as m_blk,
       "TO" as m_turnovers,
       pf as m_pf,
       pts as m_pts,
       plus_minus as m_plus_minus
from deduped
where row_num = 1;

select t.*, gd.* from fct_game_details gd
                          join teams t on t.team_id = gd.dim_team_id;

select dim_player_name,
       count(1) as num_games,
       count(CASE WHEN dim_not_with_team THEN 1 END),
       CAST(count(CASE WHEN dim_not_with_team THEN 1 END) AS REAL)/count(1) as bail_pct
from fct_game_details gd
group by 1
order by 4 desc;


select dim_player_name,
       dim_is_playing_at_home,
       count(1) as num_games,
       SUM(m_pts) as total_points,
       count(CASE WHEN dim_not_with_team THEN 1 END) as bailed_num,
       CAST(count(CASE WHEN dim_not_with_team THEN 1 END) AS REAL)/count(1) as bail_pct
from fct_game_details gd
group by 1,2
order by 6 desc

