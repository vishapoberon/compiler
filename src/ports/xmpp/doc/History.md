# XMPP source history

The BlackBox XMPP component was written by Pyotr Mikhailovich Kushnir (Пётр
Михайлович Кушнир). OberonCore's
[component page](https://oberoncore.ru/bbcc/subs/xmpp/start) and his
[29 July 2008 announcement](https://forum.oberoncore.ru/viewtopic.php?f=90&t=1104)
identify its author.

The [standalone XMPP repository](https://github.com/norayr/xmpp) preserves all
15 recovered Mercurial changesets from 2 August 2011 through 3 March 2015,
followed by Norayr Chilingarian's five VOC porting commits from 14 August 2019
and the current native port. The recovered Mercurial tip is
`a2cde5435bea63de16239c2c31e399ad0fd43ad2`.

The Git import preserves every upstream source snapshot and commit's metadata.
The 2019 commits retain their original authors, committers,
dates, timezones, messages and complete trees; only their parents changed to
join them to the recovered upstream history. The original Git and Mercurial
bundles, hashes and commit-ID mapping are preserved in the standalone
repository's [`history/` directory](https://github.com/norayr/xmpp/tree/master/history).
Its `make history-test` independently restores and verifies them.

VOC's `upstream/` directory preserves the supplied 88-file snapshot, including
31 paired text exports and native `.odc` documents. Of the 56 files at the
recovered Mercurial tip, 55 match that snapshot byte-for-byte. `Mod/Basic.odc`
differs within its final 99 bytes; both versions remain preserved. See the
[complete history record](https://github.com/norayr/xmpp/blob/master/doc/History.md)
for the archive source, conversion details and verification instructions.

Some source headers reference `Docu/BB-License`; that file is absent from the
recovered history and supplied snapshot. Author notices are retained, and
licensing confirmation remains pending.
