all: sr.se.m3u sr.se.pipe.m3u

define SCRIPT
import sys, requests
from re import sub
#print(sys.argv)

filename=sys.argv[1]
dopipe=len(sys.argv)>2 and sys.argv[2] == 'pipe'
prefix='SR '
id=lambda d: sub(r'.*/(\w+)-.*', r'\1.sr.se', d['url'])
logo=lambda d: 'https://raw.githubusercontent.com/quantenschaum/playlists/master/logos/{id}.png'.format(**d)
group=lambda d: 'Radio-SE'
pipe=lambda d: 'pipe:///usr/bin/ffmpeg -loglevel fatal -i "{url}" -c copy -metadata service_name="{name}" -metadata service_provider="{group}" -mpegts_service_type advanced_codec_digital_radio -f mpegts pipe:1'.format(**d)
template='#EXTINF:-1 tvg-id="{id}" tvg-name="{name}" tvg-logo="{logo}" group-title="{group}" radio="true",{name}\n{url}'

def read_m3u(url):
	try:
		r = requests.get(url)
		r.raise_for_status()
		for l in r.text.splitlines():
			l=l.strip()
			if '://' in l:
				return l
	except:
		pass

with open(filename) as src:
	print('#EXTM3U')
	data={}
	for line in src:
		line=line.strip()
		if line.startswith('#'):
			continue
		if not line:
			data={}
		elif '://' in line:
			if line.endswith('m3u'):
				line=read_m3u(line) or line
			data['url']=line
		else:
			if not line.startswith(prefix):
				line=prefix+line
			data['name']=line
		if len(data)==2:
			data['id']=id(data)
			data['logo']=logo(data)
			data['group']=group(data)
			if dopipe: data['url']=pipe(data)
			print(template.format(**data))
			r=requests.get(data['logo'])
			if r.status_code!=200: print('missing {logo}'.format(**data), file=sys.stderr)
endef
export SCRIPT
RUNSCRIPT := python3 -c "$$SCRIPT"

%.m3u: %.src Makefile
	$(RUNSCRIPT) $< >$@

%.pipe.m3u: %.src Makefile
	$(RUNSCRIPT) $< pipe >$@
