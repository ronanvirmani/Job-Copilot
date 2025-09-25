from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/api/v1/messages'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            # return one sample message to exercise processing
            sample = [{
                'id': 123,
                'subject': 'Test message',
                'snippet': 'This is a test',
                'classification': 'other'
            }]
            self.wfile.write(json.dumps(sample).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_PATCH(self):
        # Accept claim and update endpoints
        if self.path.startswith('/api/v1/messages'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            if self.path.endswith('/claim'):
                self.wfile.write(json.dumps({'triage_in_progress': True}).encode())
            else:
                # echo back payload
                length = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(length) if length else b''
                try:
                    data = json.loads(body.decode() or '{}')
                except Exception:
                    data = {}
                self.wfile.write(json.dumps({'received': data}).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', 4000), Handler)
    print('Mock server running on http://127.0.0.1:4000')
    server.serve_forever()
