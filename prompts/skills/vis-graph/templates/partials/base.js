// --- Common utilities for vis-graph templates ---

function escapeHTML(str) {
  return str.replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
}

// --- Common state ---
let network, allNodes, allEdges, nodesDataset, edgesDataset;
let physicsEnabled = true;
let selectedNodes = new Set();
let lastSelectedNode = null;

// --- Search ---
function setupSearch() {
  let debounce;
  document.getElementById('search').addEventListener('input', () => {
    clearTimeout(debounce);
    debounce = setTimeout(applyFilters, 200);
  });
}

// --- Clipboard & Toast ---
function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => showToast('Copied: ' + text)).catch(() => showToast('Copy failed'));
}
function copySelectedNode() { if (lastSelectedNode) copyToClipboard(lastSelectedNode); }

let toastTimer;
function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2000);
}

// --- Highlight (multi-select) ---
function highlightMultiConnected(nodeIds) {
  const connEdges = edgesDataset.get().filter(e => nodeIds.has(e.from) || nodeIds.has(e.to));
  const connNodes = new Set(nodeIds);
  connEdges.forEach(e => { connNodes.add(e.from); connNodes.add(e.to); });

  const nodeUpdates = [];
  nodesDataset.forEach(n => {
    if (nodeIds.has(n.id)) {
      nodeUpdates.push({ id: n.id, opacity: 1.0, borderWidth: 3, color: { border: COLORS.highlightEdge } });
    } else if (connNodes.has(n.id)) {
      nodeUpdates.push({ id: n.id, opacity: 1.0, borderWidth: 1 });
    } else {
      nodeUpdates.push({ id: n.id, opacity: 0.15, borderWidth: 1 });
    }
  });
  nodesDataset.update(nodeUpdates);

  const connEdgeIds = new Set(connEdges.map(e => e.id));
  const edgeUpdates = [];
  edgesDataset.forEach(e => {
    const connected = connEdgeIds.has(e.id);
    edgeUpdates.push({
      id: e.id,
      color: { color: connected ? COLORS.highlightEdge : COLORS.fadedEdge },
      width: connected ? 2 : 1,
    });
  });
  edgesDataset.update(edgeUpdates);
}

// --- Focus node (adds to multi-select) ---
function focusNode(nodeId) {
  network.focus(nodeId, { scale: 1.2, animation: { duration: 400 } });
  deactivateToolbarToggles();
  selectedNodes.add(nodeId);
  lastSelectedNode = nodeId;
  network.selectNodes([...selectedNodes]);
  highlightMultiConnected(selectedNodes);
  showNodeDetail(nodeId);
}

// --- Dep list rendering ---
function renderDepList(elementId, items) {
  const ul = document.getElementById(elementId);
  ul.innerHTML = '';
  if (items.length === 0) {
    ul.innerHTML = '<li style="color:var(--text-secondary);cursor:default">None</li>';
    return;
  }
  items.sort().forEach(item => {
    const li = document.createElement('li');
    li.textContent = item;
    li.addEventListener('click', () => focusNode(item));
    ul.appendChild(li);
  });
}

// --- Toggle all filter checkboxes ---
function toggleAllFilters(containerId, checked) {
  document.querySelectorAll(`#${containerId} input[type=checkbox]`).forEach(cb => { cb.checked = checked; });
  applyFilters();
}

// --- Toolbar toggle deactivation (override in each mode) ---
let deactivateToolbarToggles = function() {};

// --- Node interaction ---
// Override onNodeDeselect in mode JS if needed (e.g., schema's closeDetailPanel)
let onNodeDeselect = function() {
  document.getElementById('node-detail')?.classList.remove('active');
};

function onNodeClick(params) {
  if (params.nodes.length === 0) {
    selectedNodes.clear();
    lastSelectedNode = null;
    clearHighlight();
    onNodeDeselect();
    return;
  }
  const nodeId = params.nodes[0];
  if (network.isCluster && network.isCluster(nodeId)) {
    network.openCluster(nodeId);
    return;
  }
  deactivateToolbarToggles();
  const wasSelected = selectedNodes.has(nodeId);
  if (wasSelected) {
    selectedNodes.delete(nodeId);
  } else {
    selectedNodes.add(nodeId);
  }
  network.selectNodes([...selectedNodes]);
  if (selectedNodes.size === 0) {
    lastSelectedNode = null;
    clearHighlight();
    onNodeDeselect();
  } else {
    lastSelectedNode = wasSelected ? [...selectedNodes].at(-1) : nodeId;
    highlightMultiConnected(selectedNodes);
    showNodeDetail(lastSelectedNode);
  }
}

function onNodeDoubleClick(params) {
  if (params.nodes.length > 0) {
    const nodeId = params.nodes[0];
    if (network.isCluster && network.isCluster(nodeId)) {
      network.openCluster(nodeId);
      return;
    }
    network.focus(nodeId, { scale: 1.5, animation: { duration: 500 } });
    copyToClipboard(nodeId);
  }
}

// --- Filter visibility (search = opacity, filter = hidden) ---
function applyFilterVisibility(matchFn) {
  const raw = document.getElementById('search').value.toLowerCase().trim();
  const terms = raw ? raw.split(/\s*\|\s*/).filter(Boolean) : [];

  const nodeUpdates = [];
  const matchedIds = new Set();
  nodesDataset.forEach(n => {
    const orig = allNodes.find(an => an.id === n.id);
    if (!orig) return;
    const filterMatch = matchFn(n, orig);
    const idLower = n.id.toLowerCase();
    const labelLower = (n.label || '').toLowerCase();
    const searchMatch = terms.length === 0 || terms.some(t => idLower.includes(t) || labelLower.includes(t));

    if (!filterMatch) {
      nodeUpdates.push({ id: n.id, hidden: true });
    } else if (!searchMatch) {
      nodeUpdates.push({ id: n.id, hidden: false, opacity: 0.08 });
    } else {
      matchedIds.add(n.id);
      nodeUpdates.push({ id: n.id, hidden: false, opacity: orig._defaultOpacity ?? 1.0 });
    }
  });
  nodesDataset.update(nodeUpdates);

  if (terms.length > 0) {
    const edgeUpdates = [];
    edgesDataset.forEach(e => {
      const bothMatched = matchedIds.has(e.from) && matchedIds.has(e.to);
      edgeUpdates.push({ id: e.id, color: { color: bothMatched ? COLORS.dimEdge : COLORS.fadedEdge } });
    });
    edgesDataset.update(edgeUpdates);
  } else {
    const edgeUpdates = [];
    edgesDataset.forEach(e => {
      edgeUpdates.push({ id: e.id, color: { color: COLORS.dimEdge, highlight: COLORS.highlightEdge } });
    });
    edgesDataset.update(edgeUpdates);
  }

  // Prune hidden nodes from multi-select and reconcile visual state
  if (selectedNodes.size > 0) {
    for (const id of selectedNodes) {
      const n = nodesDataset.get(id);
      if (!n || n.hidden) selectedNodes.delete(id);
    }
    if (lastSelectedNode && !selectedNodes.has(lastSelectedNode)) {
      lastSelectedNode = selectedNodes.size > 0 ? [...selectedNodes].at(-1) : null;
    }
    network.selectNodes([...selectedNodes]);
    if (selectedNodes.size > 0) {
      highlightMultiConnected(selectedNodes);
    } else {
      lastSelectedNode = null;
      clearHighlight();
      onNodeDeselect();
    }
  }
}

// --- Toolbar: Reset & Physics (common buttons) ---
function setupToolbarCommon() {
  document.getElementById('btn-reset').addEventListener('click', () => {
    selectedNodes.clear();
    lastSelectedNode = null;
    network.fit({ animation: { duration: 500 } });
    clearHighlight();
    onNodeDeselect();
  });

  document.getElementById('btn-physics').addEventListener('click', function() {
    physicsEnabled = !physicsEnabled;
    this.classList.toggle('active', physicsEnabled);
    if (physicsEnabled) {
      network.setOptions({ physics: { enabled: true, stabilization: { iterations: 100 } } });
    } else {
      network.stopSimulation();
      network.setOptions({ physics: { enabled: false } });
    }
  });
}
