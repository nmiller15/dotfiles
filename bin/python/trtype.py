import textwrap


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


def main():
    print()
    output("Transaction Types:")
    print()

    output("2971   Bill")
    output("2972   Comp")
    output("2973   Adjust")
    output("2975   Refund")
    output("2976   Non-refundable")
    print()


if __name__ == "__main__":
    main()
