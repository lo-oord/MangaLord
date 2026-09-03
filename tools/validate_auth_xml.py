from pathlib import Path
import xml.etree.ElementTree as ET
ET.parse(Path('/home/ubuntu/MangaLord/app/src/main/res/values/strings.xml'))
print('strings.xml: valid XML')
