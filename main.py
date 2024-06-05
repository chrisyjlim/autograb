# You must create a Python or Node.js program that finds a matching Vehicle ID for each description in the provided input.txt file.

# The output of your program must show the matching Vehicle ID for each description, as well as a confidence score from 0 to 10. A confidence score of 0 would indicate a very uncertain match, whereas a confidence score of 10 would indicate that the match was definitely correct.

# For example, if the description did not specify the transmission type of the car, the confidence score would likely be lower than a description that did specify the transmission type (Automatic or Manual).

# If there are multiple vehicles which you find to be the most likely match, you should return the vehicle which has the most listings associated with it in the listing table.

# Your program must interact with the vehicle and listing tables by running SQL queries from within your program. You should not need to edit the SQL data.

# You can use a combination of regular expressions, sql and standard algorithms/logic to match the vehicles. Your program should print the vehicle match response for each of the provided test cases - both the matching vehicle ID as well as the confidence score.

# Example Output


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
                        matching_score=result[7])\
                        
        s = f"""Input: {search_string}\n"""\
            f"""Vehicle ID: {vr.id}\n"""\
            f"""Confidence: {vr.matching_score}\n"""
        return s


vm = VehicleMatch()
file = open("input.txt", "r")
for row in file:
    print(vm.exec_search(row.rstrip()))


