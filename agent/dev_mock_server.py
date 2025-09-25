from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/api/v1/messages'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            # return empty list to simulate no messages
            self.wfile.write(json.dumps([]).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_PATCH(self):
        # Accept claim and update endpoints
        if self.path.startswith('/api/v1/messages'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            # If it's claim endpoint, return triage_in_progress true
            if self.path.endswith('/claim'):
                self.wfile.write(json.dumps({'triage_in_progress': True}).encode())
            else:
                self.wfile.write(json.dumps({}).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', 3000), Handler)
    print('Mock server running on http://127.0.0.1:3000')
    server.serve_forever()
