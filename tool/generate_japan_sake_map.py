"""Generate a small display map from public-domain Natural Earth admin-1 data."""
import json
import math
import urllib.request
from pathlib import Path

COMMIT = 'ca96624a56bd078437bca8184e78163e5039ad19'
URL = f'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/{COMMIT}/geojson/ne_10m_admin_1_states_provinces.geojson'
ROOT = Path(__file__).resolve().parents[1]


def simplify(points, tolerance=.018):
    if len(points) <= 2:
        return points
    a, b = points[0], points[-1]
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    distances = [abs(dy * p[0] - dx * p[1] + b[0] * a[1] - b[1] * a[0]) / length
                 if length else math.hypot(p[0] - a[0], p[1] - a[1]) for p in points]
    index = max(range(len(points)), key=distances.__getitem__)
    if distances[index] <= tolerance:
        return [a, b]
    return simplify(points[:index + 1], tolerance)[:-1] + simplify(points[index:], tolerance)


def project(point, inset):
    lon, lat = point
    if inset:
        return [round(470 + (lon - 122) * 25, 2), round(610 + (28 - lat) * 25, 2)]
    return [round((lon - 128) * 38, 2), round((46 - lat) * 40, 2)]


source = Path('/tmp/sakepedia-natural-earth-admin1.geojson')
if not source.exists():
    urllib.request.urlretrieve(URL, source)
features = [f for f in json.loads(source.read_text())['features'] if f['properties']['adm0_a3'] == 'JPN']
output = []
for f in features:
    p = f['properties']
    code = int(p['iso_3166_2'].split('-')[-1])
    polygons = f['geometry']['coordinates'] if f['geometry']['type'] == 'MultiPolygon' else [f['geometry']['coordinates']]
    rings = []
    for polygon in polygons:
        for ring in polygon:
            # Keep the main islands and a southwest-islands inset. This is a
            # display/selection map, not a complete navigational boundary map.
            avg_lat = sum(p[1] for p in ring) / len(ring)
            avg_lon = sum(p[0] for p in ring) / len(ring)
            inset = avg_lat < 29
            if inset and avg_lon > 132:
                continue
            simplified = simplify(ring)
            if len(simplified) < 4:
                continue
            rings.append([project(point, inset) for point in simplified])
    output.append({'code': code, 'name': p['name_ja'], 'englishName': p['name_en'], 'rings': rings})
output.sort(key=lambda p: p['code'])
assert [p['code'] for p in output] == list(range(1, 48))
assert all(p['rings'] for p in output)
asset = {'width': 720, 'height': 760, 'source': 'Natural Earth', 'sourceUrl': URL,
         'license': 'Public domain', 'prefectures': output}
path = ROOT / 'assets/data/japan_sake_map.json'
path.write_text(json.dumps(asset, ensure_ascii=False, separators=(',', ':')) + '\n')
print(f'{len(output)} prefectures; {path.stat().st_size} bytes')
