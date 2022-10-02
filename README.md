# ancienTeX.nix

This [Nix] [flake] provides old [TeXlive] versions,
in particular for academic publishing, e.g.
on [arXiv][arXiv TeXlive] (TeXlive 2020)
or [ScholarOne] (TeXlive 2013; using best approximation: 2012).


[Nix]: https://nixos.org
[flake]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
[TeXlive]: https://tug.org/texlive/
[arXiv TeXlive]: https://arxiv.org/help/faq/texlive
[ScholarOne]: https://clarivate.com/webofsciencegroup/wp-content/uploads/sites/2/2020/09/Author-LaTex-File-Upload-Manual-ScholarOne-Manuscripts.pdf



## Configuration

**One option** is to add to your flake

~~~nix
{
  inputs.ancienTeX.url = "github:jorsn/ancienTeX.nix";

  outputs = { self, ancienTeX, ... }@inputs:
    {
      packages = ancienTeX.inputs.nixlib.lib.recursiveUpdate ancienTeX.packages {
        <your own packages>
      };
    };
}
~~~
If you don't have a flake yet, this can be achieved by running the command
~~~
$ nix flake init -t github:jorsn/ancienTeX.nix
~~~

**Another option** is to either clone this repository and make it your TeX project's top-level directory,
or to download the files and add to your top-level directory.


## Usage

You can display the available development shells with
~~~
$ nix flake show
~~~
and enter a development shell for a channel by typing, e.g.,
~~~
$ nix shell .#arxiv
~~~
or, for the default channel,
~~~
$ nix shell
~~~


## License

ISC license, see file [LICENSE](./LICENSE).
