import os
import gridfs
import imdb
import requests
from pymongo import MongoClient


connection = MongoClient("db", 27017)

database = connection['DB_NAME']

CONFIG_PATTERN = 'http://api.themoviedb.org/3/configuration?api_key=0cc913ce4bb1b776d2e5f84ad059c224'
IMG_PATTERN = 'http://api.themoviedb.org/3/movie/{imdbid}/images?api_key=0cc913ce4bb1b776d2e5f84ad059c224'
KEY = '0cc913ce4bb1b776d2e5f84ad059c224'



def _get_json(url):
    r = requests.get(url)
    return r.json()


def _download_images(urls, path='.'):
    """download all images in list 'urls' to 'path' and  download image from imdb straight into mongo"""
    for nr, url in enumerate(urls[:1]):
        r = requests.get(url)
        filetype = r.headers['content-type'].split('/')[-1]
        print(filetype)
        filename = 'title' + '_{0}.{1}'.format(nr + 1, filetype)
        filepath = os.path.join(path, filename)
        with open(filepath, 'wb') as w:
            w.write(r.content)
        fs = gridfs.GridFS(database)
        with open(filepath, 'rb') as f:
          contents = f.read()
        fs.put(contents, filename=filepath, name=id)

def get_poster_urls(imdbid):
    """ return image urls of posters for IMDB id

        returns all poster images from 'themoviedb.org'. Uses the
        maximum available size.
        Args:
            imdbid (str): IMDB id of the movie
        Returns:
            list: list of urls to the images
    """
    config = _get_json(CONFIG_PATTERN.format(key=KEY))
    base_url = config['images']['base_url']
    sizes = config['images']['poster_sizes']

    """
        'sizes' should be sorted in ascending order, so
            max_size = sizes[-1]
        should get the largest size as well.        
    """

    def size_str_to_int(x):
        return float("inf") if x == 'original' else int(x[1:])

    max_size = max(sizes, key=size_str_to_int)

    posters = _get_json(IMG_PATTERN.format(key=KEY, imdbid=imdbid))['posters']
    poster_urls = []
    for poster in posters:
        rel_path = poster['file_path']
        url = "{0}{1}{2}".format(base_url, max_size, rel_path)
        poster_urls.append(url)

    return poster_urls


def tmdb_posters(imdbid, count=None, outpath='.'):
    urls = get_poster_urls(imdbid)
    if count is not None:
        urls = urls[:count]
    _download_images(urls, outpath)



def find_id(name_movie):

    global id
    ia = imdb.IMDb()
    search = ia.search_movie(name_movie)
    open('../info.txt', 'w').write(str(search))
    text = open('../info.txt', 'r')
    idn = text.read()
    id = "tt" + idn[11:18]
    return tmdb_posters(id)


 # if __name__ == "__main__":

   # tmdb_posters(find_id(title))
