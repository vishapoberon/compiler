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

The author-supplied checkout at Mercurial revision
`61608fcd3235855d1db556a760e433254c8a6482` matches all 56 tracked files of the
corresponding recovered revision. It precedes the 3 March 2015 `XmlStream` change;
the later recovered source remains the basis of the port.

Some source headers reference `Docu/BB-License`; that file is absent from the
recovered history and supplied snapshot. The original component's
[BSD 2-Clause License](../LICENSE-BSD-2-Clause) uses the same terms as BlackBox
Component Builder. Norayr Chilingarian's VOC port and additions use
LGPL-3.0-or-later; see [NOTICE](../NOTICE) and the [LGPL text](../LICENSE).
Original author notices and archived documents remain unchanged.
