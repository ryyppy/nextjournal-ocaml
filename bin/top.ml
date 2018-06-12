let code_example = "
let a = 1 + 1 in
b = a + 2"

let _ =
  Clflags.no_std_include := false;
  Clflags.noinit := true;
  Clflags.noversion := true;
  Clflags.noprompt := true;
  Topdirs.dir_directory (Findlib.package_directory "findlib");
  Topfind.load(["yojson";"unix"]);
  Topmain.main ()
