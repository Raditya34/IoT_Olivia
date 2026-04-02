enum SystemNoticeType {
  inputOil,
  inputCharcoal,
  inputBleaching,
  filtrationDone,
}

String noticeText(SystemNoticeType t) {
  switch (t) {
    case SystemNoticeType.inputOil:
      return 'User memasukkan minyak';
    case SystemNoticeType.inputCharcoal:
      return 'User memasukkan arang';
    case SystemNoticeType.inputBleaching:
      return 'User memasukkan bleaching';
    case SystemNoticeType.filtrationDone:
      return 'Filtrasi minyak telah selesai, mohon di cek hasilnya';
  }
}
