function path = iddCanonicalPath(path)
%IDDCANONICALPATH Resolve symlinks and relative components without writing.
path=string(java.io.File(char(path)).getCanonicalPath());
end
