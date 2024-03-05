# texshell.nix

This [Nix] [flake] provides easy access to development shells for
multiple [TeXlive] versions. This is sometimes important, in particular for
academic publishing when submitting the LaTeX source to publishers using different
TeXlive versions. For example, [arXiv][arXiv TeXlive] used TeXlive 2020
for a while, while at the same time Overleaf used 2022,
Quantum Information Processing used 2023 and
[ScholarOne] still uses TeXlive 2013 (we provide 2012 as best working
approximation in Nixpkgs).

[Nix]: https://nixos.org
[flake]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
[TeXlive]: https://tug.org/texlive/
[arXiv TeXlive]: https://arxiv.org/help/faq/texlive
[ScholarOne]: https://clarivate.com/webofsciencegroup/wp-content/uploads/sites/2/2020/09/Author-LaTex-File-Upload-Manual-ScholarOne-Manuscripts.pdf


## Available TeXlive versions

Current available versions in TeXshell: 2012, 2021, 2022, 2023 (default).
2020 was removed when arXiv switched to 2022, because after 2012 until 2020,
`texdoc` didn't work in the TeXlive provided by nixpkgs, and we had a complicated workaround.

arXiv currently uses 2023.


## Usage

To fire up a shell with TeXlive available, run
~~~
$ nix shell github:jorsn/texshell.nix
~~~

The command can even be simplified by registering texshell in the flake registry:
~~~
$ nix registry add texshell github:jorsn/texshell.nix
~~~
Then, to get, e.g., TeXlive 2022, run
~~~
$ nix shell texshell#tl2022
~~~
To have (almost, see above) the same TeXlive version as [arXiv] currently uses, run 
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
