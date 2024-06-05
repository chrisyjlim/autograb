import csv
import re
from modules.sql import SQLClient
from modules.objects import VehicleResult
from string import Template

class VehicleMatch():

    def __init__(self) -> None:
        self.conn = SQLClient()

    # get and format the SQL for the matching process
    def get_sql(self, search_string: str):
        with open("sql/matching.sql", 'r') as file:
            data = file.read()
        sql = Template(data).substitute(search_value=search_string)
        return sql
    
    # run the search
    def exec_search(self, search_string: str):
        sql = self.get_sql(search_string)
        result = self.conn.exec_query(sql)
        vr= VehicleResult(id=result[0], 
                        make=result[1], 
                        model=result[2], 
                        badge=result[3], 
                        transmission_type=result[4], 
                        fuel_type=result[5], 
                        drive_type=result[6], 
                        matching_score=result[7])
                        
        s = f"""Input: {search_string}\n"""\
            f"""Vehicle ID: {vr.id}\n"""\
            f"""Confidence: {vr.matching_score}\n"""
        return s


vm = VehicleMatch()
file = open("input.txt", "r")
for row in file:
    print(vm.exec_search(row.rstrip()))


