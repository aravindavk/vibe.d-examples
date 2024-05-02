import std.conv;

import vibe.vibe;
import vibe.data.serialization;

// curl -i http://localhost:8080/params/p1/p2
// HTTP/1.1 200 OK
// Server: vibe.d/2.8.4
// Date: Sun, 14 Apr 2024 15:21:14 GMT
// Keep-Alive: timeout=10
// Content-Type: text/plain; charset=UTF-8
// Content-Length: 22
// Param1: p1, Param2: p2                          
void urlParamsHandler(HTTPServerRequest req, HTTPServerResponse res)
{
    auto param1 = req.params.get("param1");
    auto param2 = req.params.get("param2");
    
    res.writeBody("Param1: " ~ param1 ~ ", Param2: " ~ param2);
}

// curl -i "http://localhost:8080/query?filter=crash&state=open"
// HTTP/1.1 200 OK
// Server: vibe.d/2.8.4
// Date: Sun, 14 Apr 2024 15:28:30 GMT
// Keep-Alive: timeout=10
// Content-Type: text/plain; charset=UTF-8
// Content-Length: 27

// Keyword: crash, State: open
void queryParamsHandler(HTTPServerRequest req, HTTPServerResponse res)
{
    auto keyword = req.query.get("filter", "");
    auto state = req.query.get("state", "all");
    
    res.writeBody("Keyword: " ~ keyword ~ ", State: " ~ state);
}

// curl -i "http://localhost:8080/multipart/form-data" -F title=Hello -Fdata=@dub.json
// HTTP/1.1 200 OK
// Server: vibe.d/2.8.4
// Date: Sun, 14 Apr 2024 17:00:25 GMT
// Keep-Alive: timeout=10
// Content-Type: text/plain; charset=UTF-8
// Content-Length: 84

// Title: Hello, Filename: const(Segment)("dub.json", '\0'), Tempname: /tmp/vtmp.ozGDW4 
void multipartFormdataHandler(HTTPServerRequest req, HTTPServerResponse res)
{
    auto title = req.form.get("title", "");
    auto file = req.files.get("data");
    
    res.writeBody("Title: " ~ title ~ ", Filename: " ~ file.filename.to!string ~ ", Tempname: " ~ file.tempPath.to!string);
}

// curl -i "http://localhost:8080/jsondata" -H "Content-Type: application/json" -d '{"label": "cpu", "value": 55.2}'
// HTTP/1.1 200 OK
// Server: vibe.d/2.8.4
// Date: Sun, 14 Apr 2024 17:19:40 GMT
// Keep-Alive: timeout=10
// Content-Type: text/plain; charset=UTF-8
// Content-Length: 23

// Label: cpu, Value: 55.2
void jsonHandler(HTTPServerRequest req, HTTPServerResponse res)
{
    auto label = req.json["label"].to!string;
    auto value = req.json["value"].to!float;

    res.writeBody("Label: " ~ label ~ ", Value: " ~ value.to!string);
}

void setJsonHeader(HTTPServerRequest req, HTTPServerResponse res)
{
    res.contentType = "application/json; charset=utf-8";
}

struct Book
{
    string title;
    int pages;
}

// curl -i "http://localhost:8080/api/data"
// HTTP/1.1 200 OK
// Server: vibe.d/2.8.4
// Date: Mon, 15 Apr 2024 05:02:39 GMT
// Keep-Alive: timeout=10
// Content-Type: application/json; charset=utf-8
// Content-Length: 35

// {"title":"Vibe.d Book","pages":265}
void apiHandler(HTTPServerRequest req, HTTPServerResponse res)
{
    Book book;

    book.title = "Vibe.d Book";
    book.pages = 265;
    res.writeJsonBody(book);
}

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
    auto router = new URLRouter;

    router.any("/api/*", &setJsonHeader);
    router.get("/params/:param1/:param2", &urlParamsHandler);
    router.get("/query", &queryParamsHandler);
    router.post("/multipart/form-data", &multipartFormdataHandler);
    router.post("/jsondata", &jsonHandler);
    router.get("/api/data", &apiHandler);

    auto listener = listenHTTP(settings, router);
	scope (exit)
	{
		listener.stopListening();
	}

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	runApplication();
}
