import pyodbc
import matplotlib.pyplot as plt


def populationDensity(c):
    DBget = c.cursor()
    DBpush = c.cursor()

    DBpush.execute("drop table if exists population_density")

    DBpush.execute("""create table population_density(
                    x int not null ,
                    y int not null ,
                    density float default 0
                    );""")
    DBpush.commit()

    DBget.execute("""insert into population_density (x, y, density)
                    select floor(x / 10) as x, floor(y / 10) as y, sum(population) / 100 as density
                    from naselje
                    group by floor(x / 10),
                    floor(y / 10);""")
    DBpush.commit()

    for x in range(-40, 40):
        for y in range(-40, 40):
            DBpush.execute(f"""if not exists(select *
                                              from population_density
                                              where x = {x}
                                                and y = {y}) then

                                    insert into population_density
                                    values ({x}, {y}, 0);

                                end if;""")
            DBpush.commit()


def alianceDensity(c):
    DBget = c.cursor()
    DBpush = c.cursor()

    DBpush.execute("drop table if exists aliance_density")
    DBpush.execute("""create table aliance_density(
                    x int not null ,
                    y int not null ,
                    aid int,
                    density float default 0
                    );""")
    DBpush.commit()

    DBget.execute("""insert into aliance_density (x, y, aid, density)
                    WITH alianse_density AS (SELECT *,
                                                    ROW_NUMBER() OVER (PARTITION BY x,y ORDER BY density desc ) AS row_num
                                             FROM (select floor(n.x / 10)         as x,
                                                          floor(n.y / 10)         as y,
                                                          a.aid,
                                                          sum(n.population) / 100 as density
                                                   from naselje n
                                                            join igralec i on n.pid = i.pid
                                                            join aliansa a on i.aid = a.aid
                                                   group by floor(n.x / 10), floor(n.y / 10), a.aid) as ad)
                    SELECT x, y, aid, density
                    FROM alianse_density
                    WHERE row_num = 1;""")
    DBpush.commit()

    for x in range(-40, 40):
        for y in range(-40, 40):
            DBpush.execute(f"""if not exists(select *
                                                  from aliance_density
                                                  where x = {x}
                                                    and y = {y}) then

                                        insert into aliance_density
                                        values ({x}, {y}, null,0);

                                    end if;""")
            DBpush.commit()


def displayGraphe():
    fig, (ax, bx) = plt.subplots(1, 2, subplot_kw={"projection": "3d"})

    # Population density graphe
    # fetching population_density data
    x_data = DB_graphe.execute("select x from population_density;").fetchall()
    y_data = DB_graphe.execute("select y from population_density;").fetchall()
    z_data = DB_graphe.execute("select density from population_density;").fetchall()

    ax.scatter(x_data, y_data, z_data, c=z_data, cmap="plasma")
    ax.set_title("Population")
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Density")

    # fetching aliance_density data
    bx_data = DB_graphe.execute("select x from aliance_density;").fetchall()
    by_data = DB_graphe.execute("select y from aliance_density;").fetchall()
    bz_data = DB_graphe.execute("select density from aliance_density;").fetchall()

    bx.scatter(bx_data, by_data, bz_data, c=bz_data, cmap="plasma")
    bx.set_title("Aliance")
    bx.set_xlabel("X")
    bx.set_ylabel("Y")
    bx.set_zlabel("Density")

    # displaying both graphs
    plt.show()


connString = "DSN=PBSeminarska;UID=gasper;PWD=pbvaje"
cnxn = pyodbc.connect(connString)

DB_graphe = cnxn.cursor()

# populationDensity(cnxn)
# alianceDensity(cnxn)

displayGraphe()
