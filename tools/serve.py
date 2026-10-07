#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, HTTPServer
from urllib.parse import urlsplit
import os.path
import subprocess

PORT = 8001

class NoCacheHandler(SimpleHTTPRequestHandler):

	def __init__(self, *args, **kwargs):
		directory = os.path.join(os.path.dirname(__file__), "../exports/web/")
		super().__init__(*args, directory=directory, **kwargs)

	def do_GET(self):
		path = urlsplit(self.path).path
		if path in ("/", "/index.html"):
			try:
				subprocess.run(os.path.join(os.path.dirname(__file__), "export-web.sh"), check=True)
			except subprocess.CalledProcessError as error:
				self.send_error(500, f"Build failed with exit code {error.returncode}",)
				return
		super().do_GET()

	def end_headers(self):
		self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
		self.send_header("Pragma", "no-cache")
		self.send_header("Expires", "0")
		super().end_headers()

print("serving on port", PORT)
HTTPServer(("", PORT), NoCacheHandler).serve_forever()
