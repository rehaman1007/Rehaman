sx={{
  flex: "1 0 auto",
  minHeight: { xs: "auto", md: "calc(100dvh - 55px)" },
  width: "100%",
  display: "grid",
  gridTemplateColumns: {
    xs: "1fr",
    md: "1fr 1fr",
  },
  gap: {
    xs: 3,
    md: 0,
  },
  px: {
    xs: 2,
    sm: 3,
    md: 4,
    lg: 6,
  },
  py: {
    xs: 3,
    md: 3,
  },
  boxSizing: "border-box",
}}



sx={{
  minWidth: 0,
  minHeight: { xs: 600, md: 650 },
  width: "100%",
  display: "flex",
  flexDirection: "column",
}}


height: "auto",
minHeight: { xs: 600, md: 650 },
flex: 1,
display: "flex",
flexDirection: "column",
boxSizing: "border-box",
overflow: "visible",


sx={{
  flex: 1,
  minHeight: 0,
  width: "100%",
  overflow: "visible",
  pr: 0.5,
}}


<Box
  sx={{
    flexShrink: 0,
    width: "100%",
    px: 2,
    py: 1,
    position: "relative",
    zIndex: 2,
    mt: "auto",
  }}
>
  <Copyright />
</Box>




