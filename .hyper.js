module.exports = {
  config: {
    updateChannel: 'stable',
    windowSize: [960, 580],
    fontSize: 14,
    fontFamily: '"Operator Mono", "Inconsolata for Powerline", Hack, Menlo monospace',
    cursorShape: 'BLOCK',
    cursorBlink: false,
    cursorColor: '#FFFFFF',
    wickedBorder: true,
    padding: '12px 20px',
    bell: `false`,
    shell: '/bin/zsh',

    plugins: ['hyper-tabs-enhanced'],

    hyperTabs: {
      border: true,
      tabIconsColored: true,
    },
  },
};