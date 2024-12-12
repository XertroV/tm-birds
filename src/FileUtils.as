void CheckAndInitBirdsZip() {
    if (IO::FileExists(BIRDS_ZIP_GD_PATH)) return;
    IO::FileSource fs("Birds.zip");
    auto brids_zip_buf = fs.Read(fs.Size());
    IO::File f(BIRDS_ZIP_GD_PATH, IO::FileMode::Write);
    brids_zip_buf.Seek(0);
    f.Write(brids_zip_buf);
    f.Close();
    print("Copied Birds.zip to " + BIRDS_ZIP_GD_PATH);
}
