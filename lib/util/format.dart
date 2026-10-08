/// Formata valores em "mil reais" no estilo brasileiro: R$ 850 mil, R$ 1,25 mi.
String formatMoney(int mil) {
  if (mil < 1000) return 'R\$ $mil mil';
  final mi = mil / 1000;
  final digits = mi >= 100 ? 0 : (mi >= 10 ? 1 : 2);
  return 'R\$ ${mi.toStringAsFixed(digits).replaceAll('.', ',')} mi';
}

const List<String> kTaxNames = [
  'IPTU',
  'IPVA',
  'ICMS',
  'IOF',
  'CPMF',
  'Taxa do Sol',
  'Taxa do Ar',
  'Taxa das Blusinhas',
  'Imposto do Pix',
  'Taxa do Cafezinho',
  'Imposto do Churrasco',
  'Taxa da Calçada',
];

const List<String> kCaughtHeadlines = [
  'Político é flagrado com {m} em pacotes de dinheiro!',
  'Verdade vem à tona: {m} escondidos na cueca!',
  'Escândalo! {m} encontrados em apartamento de aliado',
  'Operação Mamata apreende {m} em malas',
  '"Não sabia de nada", diz político pego com {m}',
];
