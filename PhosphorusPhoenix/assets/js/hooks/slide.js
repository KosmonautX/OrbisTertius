const slider = {
    mounted() {
        x = ["/images/IMG-20220404-WA0002.jpg", "/images/IMG-20220404-WA0004.jpg", "/images/lake-gce85e5120_1920.jpg", "/images/thunderstorm-3440450__340.jpg"];

        count = -1;
        function forward() {
            count = count + 1;
            if (count <= x.length) {

                if (count == x.length) {
                    count = 0;
                }
                document.getElementById("m1").src = x[count];
                console.log(count);
            }

        }

        function backward() {
            count = count - 1;
            if (count <= x.length) {

                if (count == -1 || count == -2) {
                    index = x.length - 1;
                    count = index;
                }
                document.getElementById("m1").src = x[count];

            }
            console.log(count);
        }
    }
}

export default slider;
