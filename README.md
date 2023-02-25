# texshell.nix

This [Nix] [flake] provides easy access to development shells for
multiple [TeXlive] versions. This is important in particular for academic
publishing, since, e.g. [arXiv][arXiv TeXlive] uses TeXlive 2020
and [ScholarOne] still uses TeXlive 2013 (we provide 2012 as best working
approximation in Nixpkgs).


[Nix]: https://nixos.org
[flake]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
[TeXlive]: https://tug.org/texlive/
[arXiv TeXlive]: https://arxiv.org/help/faq/texlive
[ScholarOne]: https://clarivate.com/webofsciencegroup/wp-content/uploads/sites/2/2020/09/Author-LaTex-File-Upload-Manual-ScholarOne-Manuscripts.pdf


## Usage

To fire up a shell with TeXlive available, run
~~~
$ nix shell github:jorsn/texshell.nix
~~~

The command can even be simplified by registering texshell in the flake registry:
~~~
$ nix registry add texshell github:jorsn/texshell.nix
~~~
Then, to get, e.g., TeXlive 2020, run
~~~
$ nix shell texshell#tl2020
~~~
To have the same TeXlive version as [arXiv] currently uses, run 
~~~
$ nix shell texshell#arxiv
~~~
This also works for all supported LaTeX versions.
You can list the available development shells and more, by running
~~~
$ nix flake show
~~~


## Flake Template

To use the dev shell or a particular TeXlive version in your flake,
you can declare texshell as a flake input.

To initialize a new flake using texshell, you can run
~~~
$ nix flake init -t github:jorsn/ancienTeX.nix
~~~

## License

ISC license, see file [LICENSE](./LICENSE).
