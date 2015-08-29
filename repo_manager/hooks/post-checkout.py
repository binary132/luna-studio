#!/usr/bin/env python3

# noinspection PyUnresolvedReferences
import git
from io_utils import finfo
# noinspection PyUnresolvedReferences
from plumbum import local


def main():
    finfo("post-checkout (master branch)")
    git_cmd = local["git"]
    git_cmd[
        "submodule", "update", "--init"
    ]()
    # git_cmd[
    #     "submodule", "foreach", "-q", "--recursive",
    #     """branch="$(git config -f $toplevel/.gitmodules submodule.$name.branch)"; git checkout $branch"""
    # ]()
    # git_cmd[
    #    "submodule", "foreach", "-q", "--recursive",
    #    """commsha="$(cd $toplevel; git ls-tree @ $name | awk '{print $3}' )"; git merge $commsha"""
    # ]()


if __name__ == '__main__':
    main()