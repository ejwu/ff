import json
data = json.load(open("kiviak_ranking.json"))

for rank in data["data"]["ranks"]:
    print(rank["duration"])
