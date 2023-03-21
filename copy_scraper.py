from distutils.dir_util import copy_tree
import sys

def query_yes_no(question, default="yes"):
    """Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
            It must be "yes" (the default), "no" or None (meaning
            an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    """
    valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == "":
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' " "(or 'y' or 'n').\n")

def get_package_path():
  package_path = None
  for i in sys.path:
    if i.endswith('site-packages') or i.endswith('dist-packages'):
        package_path = i
  return package_path

def copy_scraper():
    answer = query_yes_no(f"Package will be placed in: {get_package_path()}, is this the correct package directory?"):
    if answer:
        copy_tree("Scraper_library", get_package_path())
    elif answer != True:
        path = input('Specify path or abort')
        if path != "abort":
            copy_tree("Scraper_library", path)
