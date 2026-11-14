// Özellikler (GDD 24.1). Saf veri + küçük yardımcılar; DOM ve durum bilmez.
//   kind: 'mizac' (doğuştan/yerleşik, kişilik uyumuna girer) | 'edinilmis' (olayla kazanılır)
//   opp : karşıt özellik (kişilik uyumunu düşürür)
//   hint: oyuncuya gösterilen tek satır
export const TRAITS = {
  Temkinli: { kind: 'mizac', opp: 'Gözüpek', hint: 'Riskli kararlar stres yapar; polisi karşısına almak istemez.' },
  Gözüpek: { kind: 'mizac', opp: 'Temkinli', hint: 'Gözdağı ve saldırı seçeneklerini rahat yapar.' },
  Cömert: { kind: 'mizac', opp: 'Açgözlü', hint: 'Aileyi ve adamını geri çevirmek stres yapar.' },
  Açgözlü: { kind: 'mizac', opp: 'Cömert', hint: 'Rüşvete yatkındır; ortağını satabilir.' },
  Merhametli: { kind: 'mizac', opp: 'Zalim', hint: 'Af vermek rahatlatır, hesaplaşmak çok yorar.' },
  Zalim: { kind: 'mizac', opp: 'Merhametli', hint: 'Korku salmak ona kolay gelir.' },
  'Sözünün Eri': { kind: 'mizac', opp: 'Dönek', hint: 'Söz bozmak stres yapar, saygısı iki kat düşer.' },
  Dönek: { kind: 'mizac', opp: 'Sözünün Eri', hint: 'Çıkarı gelince taraf değiştirir.' },
  Kindar: { kind: 'mizac', opp: 'Bağışlayıcı', hint: 'Kara Defter kayıtları sönmez; af vermez.' },
  Bağışlayıcı: { kind: 'mizac', opp: 'Kindar', hint: 'Kayıtlar kolay söner; af vermek ona kolay gelir.' },
  Alkolik: { kind: 'edinilmis', hint: 'Sarhoşken ağzı gevşer; sağlığı bozulur.' },
  Gazi: { kind: 'edinilmis', hint: 'Zorluğa dayanıklı; ekibi ona saygı duyar.' },
  'Hapis Yatmış': { kind: 'edinilmis', hint: 'Karakolun gözünde sicili var; sokakta saygı görür.' },
};

export const hasTrait = (c, t) => !!c && !!c.traits && c.traits.includes(t);

// Kişilik uyumu: 10 × ortak mizaç − 10 × karşıt çift, −20…+20 (GDD 24.1)
export function compat(a, b) {
  if (!a || !b) return { v: 0, shared: [], clash: [] };
  const ta = (a.traits || []).filter((t) => TRAITS[t] && TRAITS[t].kind === 'mizac');
  const tb = (b.traits || []).filter((t) => TRAITS[t] && TRAITS[t].kind === 'mizac');
  const shared = ta.filter((t) => tb.includes(t));
  const clash = [];
  for (const t of ta) if (tb.includes(TRAITS[t].opp)) clash.push([t, TRAITS[t].opp]);
  const v = Math.max(-20, Math.min(20, 10 * shared.length - 10 * clash.length));
  return { v, shared, clash };
}

// Özellik → eylem stres kuralları. Değer: + stres, − rahatlama. 'engel' = o eylem hiç yapılamaz.
export const STRESS_RULES = {
  hesap: { Merhametli: 20, Temkinli: 5, Kindar: -10, Zalim: -5 },
  af: { Merhametli: -10, Kindar: 'engel' },
  ahitBoz: { Temkinli: 5, 'Sözünün Eri': 25 },
  gozdagi: { Merhametli: 10, Cömert: 10 },
  talep: { Merhametli: 5, Cömert: 3 },
};

// Patronun özelliklerine göre bir eylemin stres bedeli; (toplam, açıklama[]) döner.
export function stressFor(patron, key) {
  const rules = STRESS_RULES[key] || {};
  let total = 0; const why = [];
  for (const t of patron.traits || []) {
    const r = rules[t];
    if (typeof r === 'number') { total += r; why.push(`${t} (${r > 0 ? '+' : ''}${r})`); }
  }
  return { total, why };
}

export const blocked = (patron, key) => (patron.traits || []).some((t) => (STRESS_RULES[key] || {})[t] === 'engel');
