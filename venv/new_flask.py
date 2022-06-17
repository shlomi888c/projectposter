from flask import Flask, render_template, request , make_response
from pymongo import MongoClient, response
from app import find_id
import gridfs
app = Flask(__name__)
import imdb
client = MongoClient("db", 27017)

db1 = client["DB_NAME"]



@app.route('/posterpath/file', methods=['POST', 'GET'])
def handle_data():
    global projectpath
    projectpath = request.form['projectFilepath']
    # find the id of movie and save it in mongo database
    (find_id(projectpath))
    # show the images and results of the search method
    ia = imdb.IMDb()
    search = ia.search_movie(projectpath)
    s = search
    open('../info.txt', 'w').write(str(search))
    text = open('../info.txt', 'r')
    idn = text.read()
    id = "tt" + idn[11:18]
    data = db1.fs.files.find_one({'name': id})
    my_id = data['_id']
    fs = gridfs.GridFS(db1)
    my_poster = fs.get(my_id).read()
    response=make_response(my_poster)
    response.content_type="image/webp"
    return response

@app.route("/index")
def index():
    return render_template("index.html")



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)