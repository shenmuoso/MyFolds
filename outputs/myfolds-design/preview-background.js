'use strict';

// One background animation lets the glass be inspected against different colours.
(() => {
  const ambient = document.querySelector('.desktop-ambient');
  const panel = document.querySelector('#background-panel');
  const toggle = document.querySelector('#background-toggle');
  const play = document.querySelector('#background-play');
  const playLabel = document.querySelector('#background-play-label');
  const status = document.querySelector('#background-motion-status');
  const channels = ['r', 'g', 'b'].map(name => document.querySelector('#background-' + name));
  const outputs = ['r', 'g', 'b'].map(name => document.querySelector('#background-' + name + '-value'));
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const cycle = [[218,151,166], [211,181,132], [151,187,160], [131,185,194], [146,169,211], [183,157,202]];
  let mode = 'rgb';
  let colour = [...cycle[0]];
  let animation = null;
  let updateTimer = null;
  let wantsMotion = !reducedMotion.matches;
  const cssColour = value => `rgb(${value.join(', ')})`;

  function reflectColour() {
    if (animation) {
      const values = getComputedStyle(ambient).backgroundColor.match(/[\d.]+/g);
      if (values?.length >= 3) colour = values.slice(0, 3).map(value => Math.round(Number(value)));
    }
    document.body.style.setProperty('--preview-chip', mode === 'warm' ? '#d8c9b8' : cssColour(colour));
    channels.forEach((input, index) => {
      input.value = colour[index];
      outputs[index].value = String(colour[index]);
    });
  }

  function syncPlayback() {
    clearInterval(updateTimer);
    updateTimer = null;
    const reduced = reducedMotion.matches;
    const running = mode === 'rgb' && wantsMotion && !reduced && !document.hidden;
    if (animation) running ? animation.play() : animation.pause();
    document.body.dataset.previewMotion = reduced ? 'reduced' : running ? 'running' : 'paused';
    play.disabled = reduced;
    playLabel.textContent = reduced ? '已暂停' : wantsMotion ? '暂停流动' : '继续流动';
    play.setAttribute('aria-label', reduced ? '已跟随系统减少动态效果' : wantsMotion ? '暂停背景流动' : '继续背景流动');
    play.querySelector('[data-icon]').dataset.icon = wantsMotion && !reduced ? 'pause' : 'play';
    play.querySelector('[data-icon]').innerHTML = icon(wantsMotion && !reduced ? 'pause' : 'play');
    status.textContent = reduced ? '减少动态效果' : wantsMotion ? '36 秒一轮' : '已固定当前颜色';
    reflectColour();
    if (running) updateTimer = setInterval(reflectColour, 250);
  }

  function buildAnimation() {
    animation?.cancel();
    ambient.style.backgroundColor = cssColour(colour);
    const stops = [colour, ...cycle.slice(1), cycle[0]];
    if (colour.some((value, index) => value !== cycle[0][index])) stops.push(colour);
    animation = ambient.animate(
      stops.map(value => ({backgroundColor: cssColour(value)})),
      {duration: 36000, iterations: Infinity, easing: 'linear'}
    );
    syncPlayback();
  }

  function setMode(nextMode) {
    reflectColour();
    mode = nextMode;
    document.body.dataset.previewBackground = mode;
    document.querySelectorAll('[data-background-mode]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.backgroundMode === mode));
    });
    document.querySelector('#background-rgb-controls').hidden = mode !== 'rgb';
    if (mode === 'warm') {
      animation?.cancel();
      animation = null;
      ambient.style.backgroundColor = '';
      syncPlayback();
    } else {
      buildAnimation();
    }
  }

  function pauseAtCurrentColour() {
    wantsMotion = false;
    syncPlayback();
  }

  function setStaticColour(value) {
    animation?.cancel();
    animation = null;
    colour = value.map(channel => Math.min(255, Math.max(0, Math.round(channel))));
    wantsMotion = false;
    ambient.style.backgroundColor = cssColour(colour);
    syncPlayback();
  }

  play.addEventListener('click', () => {
    wantsMotion = !wantsMotion;
    if (wantsMotion && !animation) buildAnimation();
    else syncPlayback();
  });
  document.querySelectorAll('[data-background-mode]').forEach(button => {
    button.addEventListener('click', () => setMode(button.dataset.backgroundMode));
  });
  document.querySelectorAll('[data-background-colour]').forEach(button => {
    button.addEventListener('click', () => setStaticColour(button.dataset.backgroundColour.split(',').map(Number)));
  });
  channels.forEach(input => {
    input.addEventListener('focus', pauseAtCurrentColour);
    input.addEventListener('pointerdown', pauseAtCurrentColour);
    input.addEventListener('input', () => setStaticColour(channels.map(channel => Number(channel.value))));
  });
  panel.addEventListener('toggle', event => toggle.setAttribute('aria-expanded', String(event.newState === 'open')));
  panel.addEventListener('keydown', event => event.stopPropagation());
  document.addEventListener('visibilitychange', syncPlayback);
  reducedMotion.addEventListener('change', syncPlayback);
  setMode('rgb');
})();
