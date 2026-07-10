from os.path import isfile

from setuptools import Extension, setup

sources = ["bindings/python/tree_sitter_mlxtran/binding.c", "src/parser.c"]
if isfile("src/scanner.c"):
    sources.append("src/scanner.c")

setup(
    ext_modules=[
        Extension(
            name="tree_sitter_mlxtran._binding",
            sources=sources,
            include_dirs=["src"],
            extra_compile_args=["-std=c11"],
            define_macros=[("PY_SSIZE_T_CLEAN", None)],
            py_limited_api=False,
        )
    ]
)
