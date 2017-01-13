# Nginx Upload Handler Configuration

This nginx configuration set up a server listening on port 8180
that can be used to upload files on the server.

The path for uploading file is ``http://127.0.0.1/upload``, just send the file using a multipart/form-data

A test page can be used to test the service at ``http://127.0.0.1/test.html``
