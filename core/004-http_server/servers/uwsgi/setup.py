from setuptools import setup, find_packages


setup(name='Aquameta-DB',
      author='Aquameta',
      author_email='eric@aquameta.com',
      description='',
      include_package_data=True,
      long_description=open('README.md', 'r').read(),
      packages=find_packages(),
      url='https://github.com/aquametalabs/aquameta',
      version='0.1',
      install_requires=['uwsgi', 'werkzeug', 'psycopg2'],
      classifiers=['Development Status :: 3 - Alpha',
                   'Intended Audience :: Developers',
                   'Operating System :: OS Independent',
                   'Programming Language :: Python',
                   'Topic :: Database'])
