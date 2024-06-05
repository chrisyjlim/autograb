import psycopg2


class SQLClient():

    def __init__(self) -> None:
        self.conn = psycopg2.connect(database="autograb", host="localhost", user="postgres", password="admin", port=5432)
        self.cursor = self.conn.cursor()

    def exec_query(self, sql):
        self.cursor.execute(sql)
        return self.cursor.fetchone()
    
    def close_connection(self):
        self.conn.close()
