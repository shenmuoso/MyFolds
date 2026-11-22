// A separate, modeless preferences window. Values live only in this design preview.
const settingsWindow = document.querySelector('#settings-window');
const settingsSections = [
  {id:'appearance', title:'外观', symbol:'transparency'},
  {id:'opening', title:'打开方式', symbol:'app'},
  {id:'shortcuts', title:'快捷键', symbol:'keyboard'}
];
let settingsSection = 'appearance';
let settingsReturnFocus;
const compactSettingsNavigation = matchMedia('(max-width:520px)');
function syncSettingsNavigation() {
  settingsWindow.querySelector('.settings-navigation')?.setAttribute('aria-orientation',compactSettingsNavigation.matches?'horizontal':'vertical');
}
compactSettingsNavigation.addEventListener('change',syncSettingsNavigation);

function settingsSelect(id, label, options, value) {
  return `<span class="settings-popup"><select id="${id}" aria-label="${label}">${options.map(option=>`<option ${option.value===value?'selected':''} value="${esc(option.value)}">${esc(option.label)}</option>`).join('')}</select>${icon('chevronUpDown')}</span>`;
}

function appearanceThumbnail(mode) {
  const miniature = tone => `<span class="mini-window ${tone}"><span class="mini-sidebar"><i></i><i></i><i></i></span><span class="mini-toolbar"></span><span class="mini-files"><i></i><i></i><i></i></span></span>`;
  return `<span class="appearance-thumbnail ${mode}" aria-hidden="true">${miniature(mode==='dark'?'mini-dark':'mini-light')}${mode==='system'?miniature('mini-dark mini-half'):''}</span>`;
}

function appearanceSettings() {
  const density = document.body.dataset.density || 'normal';
  return `<section class="settings-group" aria-label="外观模式">
    <fieldset class="appearance-picker"><legend>外观</legend><div class="appearance-choices">${[['light','浅色'],['dark','深色'],['system','自动']].map(([mode,label])=>`<label class="appearance-choice"><input type="radio" name="settings-appearance" value="${mode}" ${appearanceMode===mode?'checked':''}>${appearanceThumbnail(mode)}<span class="appearance-name">${label}</span></label>`).join('')}</div></fieldset>
    <p class="settings-group-note">选择“自动”时，外观跟随系统变化。</p>
  </section>
  <section class="settings-section-block" aria-labelledby="settings-browsing-title"><h3 id="settings-browsing-title">浏览</h3><div class="settings-group"><div class="settings-form-row"><label for="setting-density">列表密度</label>${settingsSelect('setting-density','列表密度',[{value:'normal',label:'舒适'},{value:'compact',label:'紧凑'}],density)}</div></div></section>
  <section class="settings-section-block" aria-labelledby="settings-accessibility-title"><h3 id="settings-accessibility-title">辅助功能</h3><div class="settings-group">
    <div class="settings-form-row"><label for="setting-transparency">减少透明度<small id="transparency-description">使用更实的背景，让内容更容易辨认。</small></label><input class="switch" id="setting-transparency" type="checkbox" role="switch" aria-label="减少透明度" aria-describedby="transparency-description" ${document.body.dataset.transparency==='reduced'?'checked':''}></div>
    <div class="settings-form-row"><label for="setting-contrast">提高对比度<small id="contrast-description">增强文字和控件边界的对比。</small></label><input class="switch" id="setting-contrast" type="checkbox" role="switch" aria-label="提高对比度" aria-describedby="contrast-description" ${document.body.dataset.contrast==='high'?'checked':''}></div>
  </div></section>`;
}

function openingSettings() {
  const imageApps = ['内置预览','预览','Pixelmator Pro','Affinity Photo'];
  const videoApps = ['内置预览','IINA','VLC','QuickTime Player'];
  const row = (extension,label,symbol,apps) => `<div class="settings-form-row settings-file-row"><span class="settings-file-symbol">${icon(symbol)}</span><label for="settings-default-${extension}">${label}<small>.${extension}</small></label>${settingsSelect('settings-default-'+extension,label+'默认打开方式',apps.map(name=>({value:name,label:name})),state.defaults[extension])}</div>`;
  return `<p class="settings-intro">选择在 MyFolds 中打开这些文件时使用的应用。</p>
  <section class="settings-section-block" aria-labelledby="settings-images-title"><h3 id="settings-images-title">图片</h3><div class="settings-group">${row('jpg','JPEG 图像','image',imageApps)}${row('heic','HEIC 图像','image',imageApps)}</div></section>
  <section class="settings-section-block" aria-labelledby="settings-videos-title"><h3 id="settings-videos-title">视频</h3><div class="settings-group">${row('mp4','MPEG-4 视频','film',videoApps)}</div></section>
  <p class="settings-footnote">这些选择仅用于 MyFolds。Finder 的默认打开应用仍由系统管理。</p>`;
}

function shortcutSettings() {
  const group = (title,rows) => `<section class="settings-section-block"><h3>${title}</h3><dl class="settings-group settings-shortcuts">${rows.map(([label,keys,spoken])=>`<div class="settings-form-row"><dt>${label}</dt><dd><kbd aria-label="${spoken}">${keys}</kbd></dd></div>`).join('')}</dl></section>`;
  return group('浏览',[
    ['编辑完整路径','⌘ L','Command L'],['搜索当前文件夹','⌘ F','Command F'],
    ['新建标签页','⌘ T','Command T'],['关闭标签页','⌘ W','Command W'],
    ['打开文件 / 上级目录','⌘ ↓ / ⌘ ↑','Command 下箭头 / Command 上箭头']
  ]) + group('文件操作',[
    ['剪切 / 复制 / 粘贴','⌘ X / ⌘ C / ⌘ V','Command X / Command C / Command V'],
    ['复制文件路径','⌥ ⌘ C','Option Command C'],['全选','⌘ A','Command A'],
    ['重命名','Return','Return'],['撤销文件操作','⌘ Z','Command Z']
  ]) + group('预览与设置',[
    ['快速预览 / 关闭预览','Space / Esc','空格 / Escape'],['打开设置','⌘ ,','Command 逗号']
  ]) + '<p class="settings-footnote">浏览器可能占用部分快捷键。你也可以使用工具栏和右键菜单中的同名操作。</p>';
}

function renderSettingsSection(id, focusTab=false) {
  settingsSection = id;
  const section = settingsSections.find(item=>item.id===id);
  const panel = settingsWindow.querySelector('.settings-panel');
  settingsWindow.querySelector('#settings-heading').textContent = section.title;
  settingsWindow.querySelectorAll('[data-settings-section]').forEach(button=>{
    const selected = button.dataset.settingsSection===id;
    button.setAttribute('aria-selected',String(selected));
    button.tabIndex = selected ? 0 : -1;
    if(selected && focusTab) button.focus({preventScroll:true});
  });
  panel.setAttribute('aria-labelledby','settings-tab-'+id);
  panel.innerHTML = {appearance:appearanceSettings,opening:openingSettings,shortcuts:shortcutSettings}[id]();
  panel.scrollTop = 0;
}

function syncSettingsControls() {
  if(!settingsWindow.open) return;
  settingsWindow.querySelectorAll('[name="settings-appearance"]').forEach(input=>input.checked=input.value===appearanceMode);
  const transparency=settingsWindow.querySelector('#setting-transparency');
  if(transparency) transparency.checked=document.body.dataset.transparency==='reduced';
  for(const extension of ['jpg','heic','mp4']){
    const select=settingsWindow.querySelector('#settings-default-'+extension);
    if(select) select.value=state.defaults[extension];
  }
}

function openSettings() {
  if(settingsWindow.open){syncSettingsControls();settingsWindow.querySelector('[aria-selected="true"]').focus({preventScroll:true});return;}
  settingsReturnFocus = rememberFocus();
  hidePopover();closePath();
  const zoomLabel=settingsWindow.classList.contains('settings-expanded')?'恢复设置窗口大小':'放大设置窗口';
  settingsWindow.innerHTML = `<aside class="settings-rail"><div class="settings-traffic" aria-label="设置窗口控制">
    <button class="settings-window-control settings-close" data-settings-command="close" aria-label="关闭设置" title="关闭设置"><span>${icon('close')}</span></button>
    <button class="settings-window-control settings-minimize" data-settings-command="minimize" aria-label="收起设置" title="收起设置"><span>${icon('minus')}</span></button>
    <button class="settings-window-control settings-zoom" data-settings-command="zoom" aria-label="${zoomLabel}" title="${zoomLabel}"><span>${icon('expand')}</span></button>
  </div><nav class="settings-navigation" role="tablist" aria-label="设置分类" aria-orientation="vertical">${settingsSections.map(section=>`<button role="tab" id="settings-tab-${section.id}" aria-controls="settings-panel" data-settings-section="${section.id}" aria-selected="false" tabindex="-1"><span class="settings-nav-symbol ${section.id}">${icon(section.symbol)}</span><span>${section.title}</span></button>`).join('')}</nav><div class="settings-app-name"><img src="assets/myfolds.svg" alt="" width="22" height="22"><span>MyFolds</span></div></aside>
    <div class="settings-main"><header class="settings-header"><h2 id="settings-heading"></h2><span class="settings-preview-label">设计预览</span></header><div class="settings-panel" id="settings-panel" role="tabpanel" tabindex="0"></div><p class="settings-preview-note">更改即时生效，仅保留在本次演示中。</p></div>`;
  renderSettingsSection(settingsSection);
  syncSettingsNavigation();
  settingsWindow.show();
  settingsWindow.querySelector('[aria-selected="true"]').focus({preventScroll:true});
}

function closeSettings() {settingsWindow.close();}
settingsWindow.addEventListener('close',()=>restoreFocus(settingsReturnFocus));
settingsWindow.addEventListener('click',event=>{
  const tab=event.target.closest('[data-settings-section]');
  if(tab) renderSettingsSection(tab.dataset.settingsSection);
  const command=event.target.closest('[data-settings-command]')?.dataset.settingsCommand;
  if(command==='close'||command==='minimize') closeSettings();
  if(command==='zoom'){
    const expanded=settingsWindow.classList.toggle('settings-expanded');
    const button=settingsWindow.querySelector('[data-settings-command="zoom"]');
    button.setAttribute('aria-label',expanded?'恢复设置窗口大小':'放大设置窗口');
    button.title=button.getAttribute('aria-label');
  }
});
settingsWindow.addEventListener('change',event=>{
  const control=event.target;
  if(control.name==='settings-appearance') setTheme(control.value);
  if(control.id==='setting-density') document.body.dataset.density=control.value;
  if(control.id==='setting-transparency') setTransparency(control.checked);
  if(control.id==='setting-contrast') document.body.dataset.contrast=control.checked?'high':'normal';
  if(control.id.startsWith('settings-default-')) state.defaults[control.id.replace('settings-default-','')]=control.value;
});
settingsWindow.addEventListener('keydown',event=>{
  // Preferences must not dispatch file shortcuts to the window behind it.
  event.stopPropagation();
  const command=event.metaKey||event.ctrlKey;
  if(event.key==='Escape'||(command&&event.key.toLowerCase()==='w')){event.preventDefault();closeSettings();return;}
  const tab=event.target.closest('[data-settings-section]');
  if(tab&&['ArrowDown','ArrowUp','ArrowLeft','ArrowRight','Home','End'].includes(event.key)){
    event.preventDefault();
    const index=settingsSections.findIndex(section=>section.id===settingsSection);
    const offset=['ArrowDown','ArrowRight'].includes(event.key)?1:-1;
    const next=event.key==='Home'?0:event.key==='End'?settingsSections.length-1:(index+offset+settingsSections.length)%settingsSections.length;
    renderSettingsSection(settingsSections[next].id,true);
  }
});
document.addEventListener('myfolds-appearance-change',syncSettingsControls);
document.addEventListener('click',event=>{
  if(settingsWindow.open&&!settingsWindow.contains(event.target)) syncSettingsControls();
});
