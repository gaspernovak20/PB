# 1. Naloga

# Kreiranje tabele aliansa
create table aliansa
(
    aid      int not null primary key,
    alliance varchar(100)
) as
select distinct(aid), alliance
from x_world;

# kreiranje tabele pleme
create table pleme
(
    tid   int not null primary key,
    tribe varchar(100)
);

# vstavljenje plemen
insert into pleme
values (1, "Rimljani");
insert into pleme
values (2, "Tevtoni");
insert into pleme
values (3, "Galci");
insert into pleme
values (4, "Narava");
insert into pleme
values (5, "Natarji");
insert into pleme
values (6, "Huni");
insert into pleme
values (7, "Egipčani");

# kreiranje tabele igralec
create table naselje
(
    id         int          not null primary key,
    x          int          not null,
    y          int          not null,
    vid        int          not null,
    village    varchar(100) null,
    population int          null,
    pid        int          not null,
    check ( x > -400 and x < 400 and y > -400 and y < 400)
) as
select distinct (id), x, y, vid, village, population, pid
from x_world;

# kreiranje tabele naselje
create table igralec
(
    pid    int not null primary key,
    player varchar(100),
    tid    int,
    aid    int
) as
select distinct (pid), player, tid, aid
from x_world;
# 2 naloga

# a)
create view x_view as
select id,
       x,
       y,
       tid,
       vid,
       village,
       pid,
       player,
       aid,
       alliance,
       population
from naselje n
         join igralec i using (pid)
         join pleme p using (tid)
         join aliansa a using (aid);

# b)
select *
from x_world
except
select *
from x_view
union
select *
from x_view
except
select *
from x_world;

# c) 1.
create table top5
(
    alliance       varchar(100),
    SteviloNaselij integer
) as
select a.alliance, count(*) as SteviloNaselij
from naselje n
         join igralec i on n.pid = i.pid
         join aliansa a on i.aid = a.aid
where a.aid != 0
group by a.aid
order by count(*) desc
limit 5;

# c) 2.
delimiter //
create trigger top5_insert
    after insert
    on naselje
    for each row
begin
    delete from top5 where alliance is not null;

    insert into top5 (alliance, SteviloNaselij)
    select a.alliance, count(*) as SteviloNaseli
    from naselje n
             join igralec i on n.pid = i.pid
             join aliansa a on i.aid = a.aid
    where a.aid != 0
    group by a.aid
    order by count(*) desc
    limit 5;

end //
delimiter ;


# 3. Naloga
# a)
select i.pid, i.player, n.population
from naselje n
         join igralec i on n.pid = i.pid
order by population desc
limit 1;

# b)
select count(distinct (n.pid)) as st_nadpovprecnih
from naselje n
where n.population > (select avg(population)
                      from naselje);

# c)
select *
from naselje n
         join igralec i on n.pid = i.pid
where i.aid = 0
order by x desc, y desc;

# d)
select p.tid, p.tribe, SUM(n.population) as Populacija
from naselje n
         join igralec i on n.pid = i.pid
         join pleme p on i.tid = p.tid
group by p.tid
order by sum(n.population) desc
limit 1;

# e)
# Moč Alianse gledam glede na populacij
# populacija alianse
with population_sum as (select sum(n.population) as moč
                        from naselje n
                                 join igralec i on n.pid = i.pid
                        where aid != 0
                        group by aid)

select COUNT(*) as st_nadpovprecnih_alians
from population_sum
where moč > (select avg(moč)
             from population_sum);

# f)
create temporary table bananaman_naselja
(
    id         int          not null,
    x          int          not null,
    y          int          not null,
    vid        int          not null,
    village    varchar(100) null,
    population int          null,
    pid        int          not null,
    check (`x` > -400 and `x` < 400 and `y` > -400 and `y` < 400)
) as
select n.id,
       n.x,
       n.y,
       n.vid,
       n.village,
       n.
           population,
       n.pid
from naselje n
         join igralec i on n.pid = i.pid
where i.player = "bananamen"
order by n.population desc;


# g)
delimiter //
CREATE PROCEDURE populationInRange(IN x INT, IN y INT, IN distance INT, OUT sum_population INT)
BEGIN
    DECLARE x_i INT;
    DECLARE y_i INT;
    DECLARE cur_pop INT;

    SET x_i = x - distance;
    SET y_i = y - distance;
    SET sum_population = 0;

    WHILE (x_i <= x + distance)
        DO
            IF (x_i > -400 AND x_i < 400) THEN
                SET y_i = y - distance;
                WHILE y_i <= y + distance
                    DO
                        IF (y_i > -400 AND y_i < 400) THEN
                            SELECT population
                            into cur_pop
                            FROM naselje
                            WHERE x = x_i
                              AND y = y_i
                            limit 1;

                            SET sum_population = sum_population + if(cur_pop is null, 0, cur_pop);
                        end if;
                        SET y_i = y_i + 1;
                    END WHILE;
            END IF;
            SET x_i = x_i + 1;
        END WHILE;
END //
delimiter ;

# h)
select pi.player
from (select distinct (i.pid), i.player
      from naselje n
               join igralec i on n.pid = i.pid
      where n.x between 100 and 200
        and n.y between 0 and 100) as pi
where not exists(select pid
                 from naselje n2
                 where pi.pid = n2.pid
                   and n2.x not between 100 and 200
                   and n2.y not between 0 and 100);

# i)
# navadna poizvedba
select *
from naselje
where population = 1000;

# pohitrena verzija
create index index_population on naselje (population);

# j)
with ang_igralca
         as (select n.pid, (avg(population) * 3 / 100) as avg
             from naselje n
             group by n.pid)

select *
from ang_igralca
where ang_igralca.avg > any (select population
                             from naselje
                             where ang_igralca.pid = pid);


