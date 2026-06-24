from pathlib import Path
import argparse
import re
import sys
import enum
import subprocess

def process_args(text: str) -> list[tuple[str, str]]:
    if not text:
        return []
    assert isinstance(text, str)
    args: list[str] = text.split(",")
    result: list[tuple[str, str]] = []
    for arg in args:
        arg_name_type = [a.strip() for a in arg.split(":")]
        result.append(tuple(arg_name_type))

    return result

basic_types = ["usize", "anyopaque", "void", "bool"]

def get_pure_type(body: str) -> str:
    assert len(body) > 0
    if body[0] == "*" or body[0] == "?":
        return get_pure_type(body[1:])
    if body.startswith("[*c]"):
        return get_pure_type(body[4:])
    return body



def process_function_pointer(text: str, body: re.Match) -> str:
    args_str  = body.group(1)
    assert isinstance(args_str, str)
    original_args = process_args(args_str)
    return_type: str = body.group(3)
    args: list[tuple[str, str]] = []
    for arg in original_args:
        assert len(arg) == 2
        args.append((arg[0], process_type(text, arg[1])))
    return_type = process_type(text, return_type)
    a = f"?*const fn ("
    for i, arg in enumerate(args):
        if i == (len(args) - 1):
            a += f"{arg[0]}: {arg[1]}"
        else:
            a += f"{arg[0]}: {arg[1]}, "
    a += f") {return_type}"
    return a

name_replaces: dict[str, str] = {}

def find_type(text: str, name: str) -> str:
    body = None
    if name in name_replaces:
        return name_replaces[name]

    result = re.findall("pub const SDL_malloc_func = (.*);", text, 0)

    assert len(result) == 1

    function_pointer_check = re.match("\\?\\*const fn \\((.*?)\\)\\s*(?:(callconv\\(\\.c\\)))?\\s*(.*)", result[0], 0)

    if function_pointer_check != None:
        body = process_function_pointer(text, function_pointer_check)

    assert body
    new_name = rename(name, Case.PASCAL_CASE);
    print(f"const {new_name} = {body};")
    name_replaces[name] = new_name
    return new_name

def process_type(text: str, body: str) -> str:
    pure_type = get_pure_type(body)
    if pure_type in basic_types:
        return body
    print("//", body, pure_type)
    print("//", "-"*32)
    return find_type(text, pure_type)


class Case(enum.Enum):
    KEEP = enum.auto()
    PASCAL_CASE = enum.auto()
    CAMEL_CASE = enum.auto()

def rename(name: str, case: Case) -> str:
    if name.startswith("SDL_"):
        if case == Case.PASCAL_CASE or case == case.CAMEL_CASE:
            upper = True
            new_name = ""
            for i, char in enumerate(name[4:]):
                if i == 0 and case == Case.CAMEL_CASE:
                    new_name += char.lower()
                    upper = False
                elif upper:
                    new_name += char.upper()
                    upper = False
                elif char == "_":
                    upper = True
                    continue
                else:
                    new_name += char
            return new_name
        else:
            return name[4:]
    print("old name:", name)
    assert False

def process_fn(text: str, body: str):
    result = re.match("pub extern fn (.+)\\((.*)\\) (.+);", body, 0)
    assert isinstance(result, re.Match)
    name: str = result.group(1)
    args_str = result.group(2)
    assert isinstance(args_str, str)
    original_args = process_args(args_str)
    return_type: str = result.group(3)
    args: list[tuple[str, str]] = []
    for arg in original_args:
        assert len(arg) == 2
        args.append((arg[0], process_type(text, arg[1])))
    return_type = process_type(text, return_type)
    print("//", body)
    print("//", "name:", name)
    print("//", "args:", args)
    print("//", "return type:", return_type)

    a = f"extern fn {name}("
    for i, arg in enumerate(args):
        if i == (len(args) - 1):
            a += f"{arg[0]}: {arg[1]}"
        else:
            a += f"{arg[0]}: {arg[1]}, "
    a += f") {return_type};"
    print(a)
    print(f"pub const {rename(name, Case.CAMEL_CASE)} = {name};")

    print("//", "*"*32)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(argv[0])
    _ = parser.add_argument("file", type=Path)
    args = parser.parse_args()

    assert isinstance(args.file, Path)  # pyright: ignore[reportAny]

    assert args.file.is_file()

    global text
    text = subprocess.check_output(["zig", "translate-c", str(args.file.absolute()),  "-I", "/usr/include/"], text = True)

    functions: list[str] = re.findall("pub extern fn SDL.*", text, 0)

    for function in functions:
        process_fn(text, function)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
