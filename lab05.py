import psycopg2, numpy as np
import matplotlib.pyplot as mp

def One_graf():
    con = psycopg2.connect("dbname=postgres user=postgres host=localhost password=1")

    cur = con.cursor()
    cur.execute("SELECT x, y FROM lab05.fn ORDER BY x;")

    arr = cur.fetchall()

    cur.close()
    con.close()

    x, y = np.array(arr).T

    mp.scatter(x, y, s=0.3)

    mp.title('Plot of x and y')
    mp.xlabel('x')
    mp.ylabel('y = sin{x}')

    mp.grid(True, which='both')
    mp.axhline(y=0, c="k")

    mp.show()

def Two_graf():
    con = psycopg2.connect("dbname=postgres user=postgres host=localhost password=1")

    cur = con.cursor()
    cur.execute("SELECT x, y FROM lab05.fn ORDER BY x;")

    arr = cur.fetchall()

    cur.close()
    con.close()

    x, y = np.array(arr).T

    mp.scatter(x, y, s=0.3)

    mp.title('Plot of x and y')
    mp.xlabel('x')
    mp.ylabel('y = sin{x}')

    mp.grid(True, which='both')
    mp.axhline(y=0, c='k')

    mp.show()


def graph():
    con = psycopg2.connect(
      "dbname=postgres user=postgres host=localhost password=1")

    cur = con.cursor()
    cur.execute("SELECT x, y FROM lab05.fn_file ORDER BY x;")

    arr = cur.fetchall()

    cur.close()
    con.close()

    x, y = np.array(arr).T

    mp.scatter(x, y, s=0.3)

    mp.title('Plot of x and y')
    mp.xlabel('x')
    mp.ylabel('y = sin{x}')

    mp.grid(True, which='both')
    mp.axhline(0, c="k")

    mp.show()

def file():
    con = psycopg2.connect("dbname=postgres user=postgres host=localhost password=1")

    cur = con.cursor()
    cur.execute("SELECT x, y FROM lab05.fn ORDER BY x;")

    arr = cur.fetchall()

    cur.close()
    con.close()
    f = open("sine.csv", "w")
    for row in arr:
        f.write(f"{row[0]}, {row[1]}\n")
    f.close()

#Two_graf()
One_graf()
#file()
#graph()
