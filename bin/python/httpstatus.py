#!/usr/bin/env python3

import sys
import textwrap
import argparse
from dataclasses import dataclass
from enum import Enum, auto
from types import SimpleNamespace


class Status(Enum):
    INFO = auto()
    SUCCESS = auto()
    REDIRECT = auto()
    CLIENT_ERR = auto()
    SERVER_ERR = auto()


class Frequency(Enum):
    FREQUENT = auto()
    INFREQUENT = auto()


@dataclass(frozen=True)
class HttpCode:
    name: str
    code: str
    description: str
    status: Status
    frequency: Frequency


HTTP_CODES = [
    HttpCode("Continue", "100",
             "This interim response indicates that the client should continue the request or ignore the response if the request is already finished.",
             Status.INFO, Frequency.INFREQUENT),
    HttpCode("Switching Protocols", "101",
             "This code is sent in response to an Upgrade request header from the client and indicates the protocol the server is switching to.",
             Status.INFO, Frequency.INFREQUENT),
    HttpCode("Processing", "102",
             "This code was used in WebDAV contexts to indicate that a request has been received by the server, but no status was available at the time of the response",
             Status.INFO, Frequency.INFREQUENT),
    HttpCode("Early Hints", "103",
             "This status code is primarily intended to be used with the Link header, letting the user agent start preloading resources while the server prepares a response or preconnect to an origin from which the page will need resources.",
             Status.INFO, Frequency.INFREQUENT),


    HttpCode("OK", "200", "The request succeeded.",
             Status.SUCCESS, Frequency.FREQUENT),
    HttpCode("Created", "201",
             "The request succeeded, and a new resource was created as a result.",
             Status.SUCCESS, Frequency.FREQUENT),
    HttpCode("Accepted", "202",
             "The request has been received but not yet acted upon. It is noncommittal, since there is no way in HTTP to later send an asynchronous response indicating the outcome of the request. It is intended for cases where another process or server handles the request, or for batch processing.",
             Status.SUCCESS, Frequency.FREQUENT),
    HttpCode("Non-Authoritative Information", "203",
             "This response code means the returned metadata is not exactly the same as is available from the origin server, but is collected from a local or a third-party copy. This is mostly used for mirrors or backups of another resource. Except for that specific case, the 200 OK response is preferred to this status.",
             Status.SUCCESS, Frequency.INFREQUENT),
    HttpCode("No Content", "204",
             "There is no content to send for this request, but the headers are useful. The user agent may update its cached headers for this resource with the new ones.",
             Status.SUCCESS, Frequency.FREQUENT),
    HttpCode("Reset Content", "205",
             "Tells the user agent to reset the document which sent this request.",
             Status.SUCCESS, Frequency.INFREQUENT),
    HttpCode("Partial Content", "206",
             "This response code is used in response to a range request when the client has requested a part or parts of a resource.",
             Status.SUCCESS, Frequency.FREQUENT),
    HttpCode("Multi-Status (WebDAV)", "207",
             "Conveys information about multiple resources, for situations where multiple status codes might be appropriate.",
             Status.SUCCESS, Frequency.INFREQUENT),
    HttpCode("Already Reported (WebDAV)", "208",
             "Used inside a <dav:propstat> response element to avoid repeatedly enumerating the internal members of multiple bindings to the same collection.",
             Status.SUCCESS, Frequency.INFREQUENT),
    HttpCode("IM Used (HTTP Delta encoding)", "226",
             "The server has fulfilled a GET request for the resource, and the response is a representation of the result of one or more instance-manipulations applied to the current instance.",
             Status.SUCCESS, Frequency.INFREQUENT),

    HttpCode("Multiple Choices", "300",
             "In agent-driven content negotiation, the request has more than one possible response and the user agent or user should choose one of them. There is no standardized way for clients to automatically choose one of the responses, so this is rarely used.",
             Status.REDIRECT, Frequency.INFREQUENT),
    HttpCode("Moved Permanently", "301",
             "The URL of the requested resource has been changed permanently. The new URL is given in the response.",
             Status.REDIRECT, Frequency.FREQUENT),
    HttpCode("Found", "302",
             "This response code means that the URI of requested resource has been changed temporarily. Further changes in the URI might be made in the future, so the same URI should be used by the client in future requests.",
             Status.REDIRECT, Frequency.FREQUENT),
    HttpCode("See Other", "303",
             "The server sent this response to direct the client to get the requested resource at another URI with a GET request.",
             Status.REDIRECT, Frequency.INFREQUENT),
    HttpCode("Not Modified", "304",
             "This is used for caching purposes. It tells the client that the response has not been modified, so the client can continue to use the same cached version of the response.",
             Status.REDIRECT, Frequency.INFREQUENT),
    HttpCode("Use Proxy Deprecated", "305",
             "Defined in a previous version of the HTTP specification to indicate that a requested response must be accessed by a proxy. It has been deprecated due to security concerns regarding in-band configuration of a proxy.",
             Status.REDIRECT, Frequency.INFREQUENT),
    HttpCode("unused", "306",
             "This response code is no longer used; but is reserved. It was used in a previous version of the HTTP/1.1 specification.",
             Status.REDIRECT, Frequency.INFREQUENT),
    HttpCode("Temporary Redirect", "307",
             "The server sends this response to direct the client to get the requested resource at another URI with the same method that was used in the prior request. This has the same semantics as the 302 Found response code, with the exception that the user agent must not change the HTTP method used: if a POST was used in the first request, a POST must be used in the redirected request.",
             Status.REDIRECT, Frequency.FREQUENT),
    HttpCode("Permanent Redirect", "308",
             "This means that the resource is now permanently located at another URI, specified by the Location response header. This has the same semantics as the 301 Moved Permanently HTTP response code, with the exception that the user agent must not change the HTTP method used: if a POST was used in the first request, a POST must be used in the second request.",
             Status.REDIRECT, Frequency.FREQUENT),

    HttpCode("Bad Request", "400",
             "The server cannot or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Unauthorized", "401",
             "Although the HTTP standard specifies ""unauthorized"", semantically this response means ""unauthenticated"". That is, the client must authenticate itself to get the requested response.",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Payment Required", "402",
             "The initial purpose of this code was for digital payment systems, however this status code is rarely used and no standard convention exists.",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Forbidden", "403",
             "The client does not have access rights to the content; that is, it is unauthorized, so the server is refusing to give the requested resource. Unlike 401 Unauthorized, the client's identity is known to the server.",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Not Found", "404",
             "The server cannot find the requested resource. In the browser, this means the URL is not recognized. In an API, this can also mean that the endpoint is valid but the resource itself does not exist. Servers may also send this response instead of 403 Forbidden to hide the existence of a resource from an unauthorized client. This response code is probably the most well known due to its frequent occurrence on the web.",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Method Not Allowed", "405",
             "The request method is known by the server but is not supported by the target resource. For example, an API may not allow DELETE on a resource, or the TRACE method entirely.",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Not Acceptable", "406",
             "This response is sent when the web server, after performing server-driven content negotiation, doesn't find any content that conforms to the criteria given by the user agent.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Proxy Authentication Required", "407",
             "This is similar to 401 Unauthorized but authentication is needed to be done by a proxy.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Request Timeout", "408",
             "This response is sent on an idle connection by some servers, even without any previous request by the client. It means that the server would like to shut down this unused connection. This response is used much more since some browsers use HTTP pre-connection mechanisms to speed up browsing. Some servers may shut down a connection without sending this message.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Conflict", "409",
             "This response is sent when a request conflicts with the current state of the server. In WebDAV remote web authoring, 409 responses are errors sent to the client so that a user might be able to resolve a conflict and resubmit the request.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Gone", "410",
             "This response is sent when the requested content has been permanently deleted from server, with no forwarding address. Clients are expected to remove their caches and links to the resource. The HTTP specification intends this status code to be used for ""limited-time, promotional services"". APIs should not feel compelled to indicate resources that have been deleted with this status code.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Length Required", "411",
             "Server rejected the request because the Content-Length header field is not defined and the server requires it.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Precondition Failed", "412",
             "In conditional requests, the client has indicated preconditions in its headers which the server does not meet.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Content Too Large", "413",
             "The request body is larger than limits defined by server. The server might close the connection or return a Retry-After header field.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("URI Too Long", "414",
             "The URI requested by the client is longer than the server is willing to interpret.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Unsupported Media Type", "415",
             "The media format of the requested data is not supported by the server, so the server is rejecting the request.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Range Not Satisfiable", "416",
             "The ranges specified by the Range header field in the request cannot be fulfilled. It's possible that the range is outside the size of the target resource's data.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Expectation Failed", "417",
             "This response code means the expectation indicated by the Expect request header field cannot be met by the server.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("I'm a teapot", "418",
             "The server refuses the attempt to brew coffee with a teapot.",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Misdirected Request", "421",
             "The request was directed at a server that is not able to produce a response. This can be sent by a server that is not configured to produce responses for the combination of scheme and authority that are included in the request URI.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Unprocessable Content (WebDAV)", "422",
             "The request was well-formed but was unable to be followed due to semantic errors.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Locked (WebDAV)", "423",
             "The resource that is being accessed is locked.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Failed Dependency (WebDAV)", "424",
             "The request failed due to failure of a previous request.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Too Early Experimental", "425",
             "Indicates that the server is unwilling to risk processing a request that might be replayed.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Upgrade Required", "426",
             "The server refuses to perform the request using the current protocol but might be willing to do so after the client upgrades to a different protocol. The server sends an Upgrade header in a 426 response to indicate the required protocol(s).",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Precondition Required", "428",
             "The origin server requires the request to be conditional. This response is intended to prevent the 'lost update' problem, where a client GETs a resource's state, modifies it and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Too Many Requests", "429",
             "The user has sent too many requests in a given amount of time (rate limiting).",
             Status.CLIENT_ERR, Frequency.FREQUENT),
    HttpCode("Request Header Fields Too Large", "431",
             "The server is unwilling to process the request because its header fields are too large. The request may be resubmitted after reducing the size of the request header fields.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Unavailable For Legal Reasons", "451",
             "The user agent requested a resource that cannot legally be provided, such as a web page censored by a government.",
             Status.CLIENT_ERR, Frequency.INFREQUENT),
    HttpCode("Internal Server Error", "500",
             "The server has encountered a situation it does not know how to handle. This error is generic, indicating that the server cannot find a more appropriate 5XX status code to respond with.",
             Status.SERVER_ERR, Frequency.FREQUENT),
    HttpCode("Not Implemented", "501",
             "The request method is not supported by the server and cannot be handled. The only methods that servers are required to support (and therefore that must not return this code) are GET and HEAD.",
             Status.SERVER_ERR, Frequency.FREQUENT),
    HttpCode("Bad Gateway", "502",
             "This error response means that the server, while working as a gateway to get a response needed to handle the request, got an invalid response.",
             Status.SERVER_ERR, Frequency.FREQUENT),
    HttpCode("Service Unavailable", "503",
             "The server is not ready to handle the request. Common causes are a server that is down for maintenance or that is overloaded. Note that together with this response, a user-friendly page explaining the problem should be sent. This response should be used for temporary conditions and the Retry-After HTTP header should, if possible, contain the estimated time before the recovery of the service. The webmaster must also take care about the caching-related headers that are sent along with this response, as these temporary condition responses should usually not be cached.",
             Status.SERVER_ERR, Frequency.FREQUENT),
    HttpCode("Gateway Timeout", "504",
             "This error response is given when the server is acting as a gateway and cannot get a response in time.",
             Status.SERVER_ERR, Frequency.FREQUENT),
    HttpCode("HTTP Version Not Supported", "505",
             "The HTTP version used in the request is not supported by the server.",
             Status.SERVER_ERR, Frequency.INFREQUENT),
    HttpCode("Variant Also Negotiates", "506",
             "The server has an internal configuration error: during content negotiation, the chosen variant is configured to engage in content negotiation itself, which results in circular references when creating responses.",
             Status.SERVER_ERR, Frequency.INFREQUENT),
    HttpCode("Insufficient Storage (WebDAV)", "507",
             "The method could not be performed on the resource because the server is unable to store the representation needed to successfully complete the request.",
             Status.SERVER_ERR, Frequency.INFREQUENT),
    HttpCode("Loop Detected (WebDAV)", "508",
             "The server detected an infinite loop while processing the request.",
             Status.SERVER_ERR, Frequency.INFREQUENT),
    HttpCode("Not Extended", "510",
             "The client request declares an HTTP Extension (RFC 2774) that should be used to process the request, but the extension is not supported.",
             Status.SERVER_ERR, Frequency.INFREQUENT),
    HttpCode("Network Authentication Required", "511",
             "Indicates that the client needs to authenticate to gain network access",
             Status.SERVER_ERR, Frequency.INFREQUENT),
]


def output(s: str):
    indent = 4
    width = 80

    formatted = textwrap.fill(
        s,
        width=width,
        initial_indent=" " * indent,
        subsequent_indent=" " * indent,
    )
    print(formatted)


def print_code(code: HttpCode, include_description: bool = False):
    output(f'{code.code} {code.name}')
    if include_description:
        output(code.description)
        print()


def print_single_code(num: int, include_description: bool):
    if (not 00 <= num <= 599):
        print('enter a three-digit HTTP status code', file=sys.stderr)
        exit(65)

    code = next((c for c in HTTP_CODES if c.code == str(num)), None)
    if not code:
        print(f'"{str(num)}" is not a valid HTTP status code.', file=sys.stderr)
        exit(1)

    print()
    print_code(code, include_description)


def filter_codes(codes: list[HttpCode], filters):
    filtered_codes = []

    if (filters.all):
        return codes

    if (not filters.status):
        return [code for code in codes if code.frequency == Frequency.FREQUENT]

    if (filters.status):
        if (filters.success):
            filtered_codes.extend(
                [c for c in codes if c.status == Status.SUCCESS])

        if (filters.info):
            filtered_codes.extend(
                [c for c in codes if c.status == Status.INFO])

        if (filters.redirect):
            filtered_codes.extend(
                [c for c in codes if c.status == Status.REDIRECT])

        if (filters.client_err):
            filtered_codes.extend(
                [c for c in codes if c.status == Status.CLIENT_ERR])

        if (filters.server_err):
            filtered_codes.extend(
                [c for c in codes if c.status == Status.SERVER_ERR])

    return filtered_codes


def print_codes(filters, verbose: bool):
    codes = filter_codes(HTTP_CODES, filters)

    output("HTTP Status Codes:")
    print()
    for code in codes:
        print_code(code, verbose)


def to_filters(args):
    filters = SimpleNamespace(
        status=False,
        success=False,
        info=False,
        redirect=False,
        client_err=False,
        server_err=False,
        all=False,
    )

    if (args.all):
        filters.all = True
        filters.status = False
        return filters

    if (not args.success and
            not args.info and
            not args.redirect and
            not args.client_err and
            not args.server_err):
        return filters

    filters.status = True
    filters.success = args.success
    filters.info = args.info
    filters.redirect = args.redirect
    filters.client_err = args.client_err
    filters.server_err = args.server_err

    return filters


def main():
    parser = argparse.ArgumentParser(
        "httpstatus", description="a helpful list of HTTP status codes")

    parser.add_argument(
        "code",
        nargs="?",
        type=int,
        help="HTTP status code (e.g. 404)"
    )

    parser.add_argument("-a", "--all", action="store_true",
                        help="show all HTTP status codes")

    parser.add_argument("-v", "--verbose", action="store_true",
                        help="display detaild descriptions")

    parser.add_argument("-i", "--info", action="store_true",
                        help="1xx - codes indicating information responses")
    parser.add_argument("-s", "--success", action="store_true",
                        help="2xx - codes indicating success")
    parser.add_argument("-r", "--redirect", action="store_true",
                        help="3xx - codes indicating redirection")
    parser.add_argument("-c", "--client-err", action="store_true",
                        help="4xx - codes indicating client erorr")
    parser.add_argument("-S", "--server-err", action="store_true",
                        help="5xx - codes indicating server erorr")

    args = parser.parse_args()
    if (args.code):
        print_single_code(args.code, True)
        exit(0)

    filters = to_filters(args)

    print_codes(filters, args.verbose)
    exit(0)


if __name__ == "__main__":
    main()
