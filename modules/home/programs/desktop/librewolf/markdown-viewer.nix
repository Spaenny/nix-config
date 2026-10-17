{
  lib,
  buildFirefoxXpiAddon,
}:

# "Markdown Viewer" by simov is not part of rycee's firefox-addons collection,
# so it is built here with the same builder that collection uses.
# Update via the AMO API: https://addons.mozilla.org/api/v5/addons/addon/markdown-viewer-chrome/
buildFirefoxXpiAddon {
  pname = "markdown-viewer";
  version = "5.2.2";
  addonId = "markdown-viewer@outofindex.com";
  url = "https://addons.mozilla.org/firefox/downloads/file/4186249/markdown_viewer_chrome-5.2.2.xpi";
  sha256 = "b1f328c3067897858054b9c7260d0f6c43579873412e580337c81c6659f4d2fc";
  meta = with lib; {
    homepage = "https://github.com/simov/markdown-viewer";
    description = "Markdown Viewer with 30+ Themes, Dark Mode, MathJax, Mermaid diagrams, Syntax Highlighted code blocks";
    license = licenses.mit;
    mozPermissions = [
      "storage"
      "scripting"
    ];
    platforms = platforms.all;
  };
}
