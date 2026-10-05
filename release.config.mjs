export const analyzer = {
  preset: "conventionalcommits",
  releaseRules: [
    { type: "ci", release: "patch" },
    { type: "build", release: "patch" },
  ],
};

export const notes = {
  preset: "conventionalcommits",
  presetConfig: {
    types: [
      { type: "feat", section: "Novidades" },
      { type: "fix", section: "Correcoes" },
      { type: "perf", section: "Desempenho" },
      { type: "ci", section: "Automacao" },
      { type: "build", section: "Distribuicao" },
      { type: "docs", section: "Documentacao" },
      { type: "test", section: "Testes" },
    ],
  },
};

export default {
  branches: ["main"],
  repositoryUrl: "https://github.com/matheus013/torre-das-cem-marcas.git",
  tagFormat: "v${version}",
  plugins: [
    ["@semantic-release/commit-analyzer", analyzer],
    ["@semantic-release/release-notes-generator", notes],
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md", changelogTitle: "# Changelog" }],
    "./tools/release/publish-plugin.mjs",
    ["@semantic-release/git", {
      assets: ["CHANGELOG.md", "VERSION"],
      message: "chore(release): ${nextRelease.version} [skip ci]",
    }],
  ],
};
